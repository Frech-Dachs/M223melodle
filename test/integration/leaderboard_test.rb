require "test_helper"

class LeaderboardTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  setup do
    @host = users(:alice)
    @anna = User.create!(email: "anna@example.com", display_name: "Anna", password: "a-long-password-1")
    @outsider = User.create!(email: "o@example.com", display_name: "O", password: "a-long-password-1")
    @group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    Group.join!(@group.invite_code, @anna)
    @song = @group.songs.create!(title: "Wonderwall", artist: "Oasis", audio_url: "/audio/a.mp3", added_by: @host)
  end

  def login(user, password = "a-long-password-1")
    post session_path, params: { email: user.email, password: password }
  end

  test "leaderboard is sorted by points with ties sharing a rank" do
    @group.scores.find_by(user: @anna).add_points!(80)
    @group.scores.find_by(user: @host).add_points!(80)
    login(@anna)
    get group_leaderboard_path(@group)
    assert_response :success
    assert_select "tbody tr", 2
    assert_select "tbody tr:first-child td:first-child", "1"
    assert_select "tbody tr:last-child td:first-child", "1"
  end

  test "leaderboard shows played rounds" do
    round = Round.start!(@group, @song, @host)
    round.guess!(@anna, "Wonderwall")
    login(@anna)
    get group_leaderboard_path(@group)
    assert_select "tr.me td:nth-child(3)", "1"
    assert_select "tr.me td:last-child", "100"
  end

  test "outsiders get 404" do
    login(@outsider)
    get group_leaderboard_path(@group)
    assert_response :not_found
  end

  test "starting, guessing and finishing a round broadcast page refreshes" do
    assert_enqueued_jobs 1, only: Turbo::Streams::BroadcastStreamJob do
      Round.start!(@group, @song, @host)
    end
    round = @group.rounds.active.first
    clear_enqueued_jobs
    round.guess!(@anna, "Wonderwall")
    assert_enqueued_jobs(1, only: Turbo::Streams::BroadcastStreamJob)
  end
end
