require "test_helper"

class SchemaConstraintsTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @group = Group.create!(name: "Testers", member_limit: 2)
    @song = @group.songs.create!(title: "T", artist: "A", audio_url: "/a.mp3", added_by: @user)
  end

  test "group gets an invite code and validates member limit" do
    assert_equal 8, @group.invite_code.length
    assert_not Group.new(name: "x", member_limit: 0).valid?
  end

  test "membership is unique per user and group, even at DB level" do
    @group.memberships.create!(user: @user, role: :host)
    assert_raises(ActiveRecord::RecordNotUnique) { Membership.new(user: @user, group: @group).save!(validate: false) }
  end

  test "score is unique per user and group and increments atomically" do
    score = Score.create!(user: @user, group: @group)
    assert_raises(ActiveRecord::RecordNotUnique) { Score.new(user: @user, group: @group).save!(validate: false) }
    Score.find(score.id).add_points!(50)
    score.add_points!(30)
    assert_equal 80, score.reload.total_points
  end

  test "only one active round per group" do
    start = -> { @group.rounds.create!(song: @song, started_by: @user, started_at: Time.current) }
    start.call
    assert_raises(ActiveRecord::RecordNotUnique) { start.call }
  end

  test "finished rounds do not block a new active round" do
    @group.rounds.create!(song: @song, started_by: @user, started_at: Time.current, status: :finished)
    assert @group.rounds.create!(song: @song, started_by: @user, started_at: Time.current)
  end

  test "one participation per user and round" do
    round = @group.rounds.create!(song: @song, started_by: @user, started_at: Time.current)
    round.participations.create!(user: @user)
    assert_raises(ActiveRecord::RecordNotUnique) { Participation.new(user: @user, round: round).save!(validate: false) }
  end

  test "duplicate song per group is rejected" do
    assert_not @group.songs.build(title: "T", artist: "A", audio_url: "/b.mp3", added_by: @user).valid?
  end
end
