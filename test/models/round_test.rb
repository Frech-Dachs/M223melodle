require "test_helper"

class RoundTest < ActiveSupport::TestCase
  setup do
    @host = users(:alice)
    @anna = User.create!(email: "anna@example.com", display_name: "Anna", password: "a-long-password-1")
    @ben = User.create!(email: "ben@example.com", display_name: "Ben", password: "a-long-password-1")
    @group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    [ @anna, @ben ].each { |u| Group.join!(@group.invite_code, u) }
    @song = @group.songs.create!(title: "Bohemian Rhapsody", artist: "Queen", audio_url: "/audio/a.mp3", added_by: @host)
  end

  def start = Round.start!(@group, @song, @host)
  def points(user) = Score.find_by(user: user, group: @group).total_points

  test "each player has their own stage, advancing only after their own wrong guess" do
    round = start
    round.update_columns(started_at: 1.hour.ago) # time does not matter
    assert_equal 0, round.stage_for(@anna)
    round.guess!(@anna, "nope")
    assert_equal 1, round.stage_for(@anna)
    assert_equal Round::STAGES[1], round.clip_seconds_for(@anna)
    assert_equal 0, round.stage_for(@ben)
    assert_equal Round::STAGES[0], round.clip_seconds_for(@ben)
  end

  test "guess is normalised" do
    round = start
    assert round.correct_guess?("  bohemian   RHAPSODY! ")
    assert_not round.correct_guess?("Bohemian")
  end

  test "players may play at different times and get points for their own stage" do
    round = start
    assert_equal :correct, round.guess!(@anna, "Bohemian Rhapsody")
    assert_equal 100, points(@anna)
    assert round.reload.active? # host and ben have not played yet
    3.times { assert_equal :wrong, round.guess!(@ben, "nope") }
    assert_equal :correct, round.guess!(@ben, "bohemian rhapsody")
    assert_equal 40, points(@ben)
    assert round.reload.active? # the host can still join later
    assert_equal :correct, round.guess!(@host, "Bohemian Rhapsody")
    assert round.reload.finished?
  end

  test "wrong guesses are not booked as participation results" do
    round = start
    assert_equal :wrong, round.guess!(@anna, "nope")
    participation = round.participation_for(@anna)
    assert_not participation.finished?
    assert_equal 0, participation.points
    assert_equal :correct, round.guess!(@anna, "Bohemian Rhapsody")
  end

  test "a second guess after finishing is rejected and scores nothing" do
    round = start
    round.guess!(@anna, "Bohemian Rhapsody")
    assert_equal :already, round.guess!(@anna, "Bohemian Rhapsody")
    assert_equal 100, points(@anna)
  end

  test "a player who is out of tries is done with 0 points, the round goes on for the others" do
    round = start
    (Round::STAGES.size - 1).times { assert_equal :wrong, round.guess!(@anna, "nope") }
    assert_equal :out_of_tries, round.guess!(@anna, "nope")
    assert round.finished_by?(@anna)
    assert_equal 0, points(@anna)
    assert_equal :already, round.guess!(@anna, "Bohemian Rhapsody")
    assert round.reload.active?
  end

  test "round finishes when every member is done" do
    round = start
    round.guess!(@host, "Bohemian Rhapsody")
    round.guess!(@anna, "Bohemian Rhapsody")
    assert round.reload.active?
    Round::STAGES.size.times { round.guess!(@ben, "nope") }
    assert round.reload.finished?
    assert_equal :closed, round.guess!(@anna, "Bohemian Rhapsody")
  end

  test "host can finish early, players who did not play get 0 points" do
    round = start
    round.guess!(@anna, "Bohemian Rhapsody")
    round.finish!
    assert round.reload.finished?
    assert_equal 3, round.participations.count
    assert_equal({ true => 1, false => 2 }, round.participations.group(:correct).count.transform_keys { |k| k })
    assert round.participations.all?(&:finished?)
    assert_equal :closed, round.guess!(@ben, "Bohemian Rhapsody")
  end

  test "only one active round per group, a second start is rejected" do
    start
    assert_raises(Round::AlreadyActive) { start }
    assert_equal 1, @group.rounds.active.count
  end

  test "a finished round does not block a new start" do
    round = start
    round.finish!
    assert_nothing_raised { start }
  end
end
