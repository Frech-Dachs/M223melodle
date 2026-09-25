require "test_helper"

class ActivitiesTest < ActionDispatch::IntegrationTest
  setup do
    @host = users(:alice)
    @bob = User.create!(email: "bob@example.com", display_name: "Bob", password: "a-long-password-1")
    @outsider = User.create!(email: "o@example.com", display_name: "O", password: "a-long-password-1")
  end

  def login(user, password = "a-long-password-1")
    delete session_path
    post session_path, params: { email: user.email, password: password }
  end

  def login_host = login(@host, "correct-horse-battery")

  def actions(group) = group.activities.order(:id).pluck(:action)

  test "group creation, join, song, round and guesses are logged with the right actor" do
    login_host
    post groups_path, params: { group: { name: "G", member_limit: 5 } }
    group = Group.last
    post songs_path_for(group), params: { song: { title: "Wonderwall", artist: "Oasis", audio_url: "/audio/a.mp3" } }
    login(@bob)
    post join_path, params: { invite_code: group.invite_code }
    login_host
    post group_rounds_path(group, song_id: group.songs.first.id)
    round = group.rounds.first
    login(@bob)
    post round_guesses_path(round), params: { guess: "nope" }
    post round_guesses_path(round), params: { guess: "wonderwall" }

    assert_equal %w[group_created song_added member_joined round_started guess_wrong guess_correct], actions(group)
    assert_equal [ @host, @host, @bob, @host, @bob, @bob ], group.activities.order(:id).map(&:actor)
  end

  test "actor is the logged-in user and not a request parameter" do
    login_host
    post groups_path, params: { group: { name: "G", member_limit: 5 }, actor_id: @bob.id }
    assert_equal @host, Group.last.activities.first.actor
  end

  test "round end is logged as a system event" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    song = group.songs.create!(title: "T", artist: "A", audio_url: "/a.mp3", added_by: @host)
    round = Round.start!(group, song, @host)
    round.finish!
    finished = group.activities.find_by(action: "round_finished")
    assert_nil finished.actor
    assert_equal "Melodle", finished.actor_name
  end

  test "removing a member and a song are logged" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    Group.join!(group.invite_code, @bob)
    song = group.songs.create!(title: "T", artist: "A", audio_url: "/a.mp3", added_by: @host)
    login_host
    delete group_song_path(group, song)
    delete group_membership_path(group, group.memberships.find_by(user: @bob))
    assert_equal %w[song_removed member_removed], actions(group).last(2)
  end

  test "feed shows activities to members, 404 for outsiders" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    login_host
    get group_activities_path(group)
    assert_response :success
    assert_select "li", /hat die Gruppe erstellt/
    login(@outsider)
    get group_activities_path(group)
    assert_response :not_found
  end

  test "if the activity cannot be saved the change is rolled back" do
    with_failing_activity do
      assert_raises(ActiveRecord::RecordInvalid) { Group.create_with_host!({ name: "G", member_limit: 5 }, @host) }
    end
    assert_equal 0, Group.where(name: "G").count
    assert_equal 0, Membership.count
    assert_equal 0, Score.count
  end

  test "a failed activity rolls back a started round and a booked guess" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    Group.join!(group.invite_code, @bob)
    song = group.songs.create!(title: "T", artist: "A", audio_url: "/a.mp3", added_by: @host)
    with_failing_activity do
      assert_raises(ActiveRecord::RecordInvalid) { Round.start!(group, song, @host) }
    end
    assert_equal 0, Round.count
    round = Round.start!(group, song, @host)
    with_failing_activity do
      assert_raises(ActiveRecord::RecordInvalid) { round.guess!(@bob, "T") }
    end
    assert_equal 0, round.participations.count
    assert_equal 0, Score.find_by(user: @bob, group: group).total_points
  end

  private

  # Makes Activity.record! fail, to prove that the surrounding change is rolled back.
  def with_failing_activity
    original = Activity.method(:record!)
    Activity.define_singleton_method(:record!) { |**| raise ActiveRecord::RecordInvalid }
    yield
  ensure
    Activity.define_singleton_method(:record!, original)
  end

  def songs_path_for(group) = group_songs_path(group)
end
