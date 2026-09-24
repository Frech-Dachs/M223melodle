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

  test "stage is derived from the server clock" do
    round = start
    t = round.started_at
    assert_equal 0, round.current_stage(t + 1)
    assert_equal 1, round.current_stage(t + Round::STAGE_DURATION + 1)
    assert_equal 6, round.current_stage(t + 6 * Round::STAGE_DURATION + 1)
    assert_nil round.current_stage(t + 7 * Round::STAGE_DURATION)
    assert round.expired?(t + 7 * Round::STAGE_DURATION)
  end

  test "guess is normalised" do
    round = start
    assert round.correct_guess?("  bohemian   RHAPSODY! ")
    assert_not round.correct_guess?("Bohemian")
  end

  test "correct guess gives points of the current stage" do
    round = start
    assert_equal :correct, round.guess!(@anna, "Bohemian Rhapsody", round.started_at + 1)
    assert_equal 100, points(@anna)
    assert round.reload.active? # host and ben have not guessed yet
    assert_equal :correct, round.guess!(@ben, "bohemian rhapsody", round.started_at + Round::STAGE_DURATION * 3 + 1)
    assert_equal 40, points(@ben)
  end

  test "wrong guess gives nothing and can be repeated" do
    round = start
    assert_equal :wrong, round.guess!(@anna, "nope", round.started_at + 1)
    assert_equal 0, round.participations.count
    assert_equal :correct, round.guess!(@anna, "Bohemian Rhapsody", round.started_at + 2)
  end

  test "a second correct guess by the same user is rejected and scores nothing" do
    round = start
    round.guess!(@anna, "Bohemian Rhapsody", round.started_at + 1)
    assert_equal :already, round.guess!(@anna, "Bohemian Rhapsody", round.started_at + 2)
    assert_equal 100, points(@anna)
  end

  test "guess after the last stage is closed and finishes the round with 0 points" do
    round = start
    assert_equal :closed, round.guess!(@anna, "Bohemian Rhapsody", round.started_at + 7 * Round::STAGE_DURATION)
    assert round.reload.finished?
    assert_equal 3, round.participations.count
    assert_equal [ 0 ], round.participations.pluck(:points).uniq
    assert_equal 0, points(@anna)
  end

  test "round finishes when every member has guessed" do
    round = start
    [ @host, @anna, @ben ].each { |u| round.guess!(u, "Bohemian Rhapsody", round.started_at + 1) }
    assert round.reload.finished?
    assert_equal :closed, round.guess!(@anna, "Bohemian Rhapsody", round.started_at + 2)
  end

  test "only one active round per group, a second start is rejected" do
    start
    assert_raises(Round::AlreadyActive) { start }
    assert_equal 1, @group.rounds.active.count
  end

  test "an expired round does not block a new start" do
    round = start
    round.update_columns(started_at: 1.hour.ago)
    assert_nothing_raised { start }
    assert round.reload.finished?
  end
end
