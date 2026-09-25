require "test_helper"

# Real concurrency tests: several threads with their own DB connections.
# Transactional tests would wrap everything in one connection, so they are switched off here
# and the created rows are removed by hand.
class ConcurrencyTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  self.use_transactional_tests = false

  setup do
    @host = make_user("host")
    @group = Group.create_with_host!({ name: "Race", member_limit: 2 }, @host)
    @song = @group.songs.create!(title: "Wonderwall", artist: "Oasis", audio_url: "/a.mp3", added_by: @host)
  end

  teardown do
    [ Activity, Participation, Round, Score, Membership, Song, Group ].each(&:delete_all)
    User.where("email LIKE ?", "%@race.test").delete_all
  end

  test "two users racing for the last seat: exactly one is admitted" do
    users = 2.times.map { |i| make_user("joiner#{i}") }
    results = with_slow_full_check do
      in_parallel(users) do |user|
        Group.join!(@group.invite_code, user)
        :joined
      rescue Group::Full
        :full
      end
    end

    assert_equal [ :full, :joined ], results.sort
    assert_equal 2, @group.memberships.count # host + one player, never more than the limit
  end

  test "many users racing for the last seat never exceed the member limit" do
    users = 8.times.map { |i| make_user("many#{i}") }
    results = in_parallel(users) do |user|
      Group.join!(@group.invite_code, user)
      :joined
    rescue Group::Full
      :full
    end

    assert_equal 1, results.count(:joined)
    assert_equal 2, @group.memberships.count
  end

  test "the same user joining twice at once gets one membership" do
    user = make_user("twice")
    @group.update!(member_limit: 10)
    results = in_parallel([ user, user ]) do |u|
      Group.join!(@group.invite_code, u)
      :joined
    rescue Group::AlreadyMember
      :already
    end

    assert_equal [ :already, :joined ], results.sort
    assert_equal 1, @group.memberships.where(user: user).count
  end

  test "double start (double click or retry) creates exactly one active round" do
    results = in_parallel([ @host, @host, @host ]) do |user|
      Round.start!(@group, @song, user)
      :started
    rescue Round::AlreadyActive
      :already_active
    end

    assert_equal [ :already_active, :already_active, :started ], results.sort
    assert_equal 1, @group.rounds.active.count
  end

  test "concurrent increments of one score do not lose updates" do
    score = @group.scores.find_by(user: @host)
    in_parallel(Array.new(10, score.id)) { |id| Score.find(id).add_points!(10) }

    assert_equal 100, score.reload.total_points
  end

  test "several players solving the round at the same moment are all booked correctly" do
    @group.update!(member_limit: 10)
    players = 5.times.map { |i| make_user("player#{i}") }
    players.each { |u| Group.join!(@group.invite_code, u) }
    round = Round.start!(@group, @song, @host)

    results = in_parallel(players) { |user| Round.find(round.id).guess!(user, "Wonderwall") }

    assert_equal [ :correct ] * 5, results
    assert_equal 5, round.participations.count
    players.each { |u| assert_equal 100, @group.scores.find_by(user: u).total_points }
    assert round.reload.active? # the host has not guessed yet
  end

  test "the same player submitting the correct answer twice at once scores once" do
    player = make_user("solo")
    @group.update!(member_limit: 10)
    Group.join!(@group.invite_code, player)
    round = Round.start!(@group, @song, @host)

    results = in_parallel([ player, player ]) { |user| Round.find(round.id).guess!(user, "Wonderwall") }

    assert_equal [ :already, :correct ], results.sort
    assert_equal 1, round.participations.where(user: player).count
    assert_equal 100, @group.scores.find_by(user: player).total_points
  end

  private

  # Widens the gap between "is there a free seat?" and "take it", so a missing lock shows up reliably.
  module SlowFullCheck
    def full?
      super.tap { sleep 0.1 }
    end
  end

  def with_slow_full_check
    Group.prepend(SlowFullCheck)
    yield
  ensure
    SlowFullCheck.send(:remove_method, :full?) # neutralise for later tests
    SlowFullCheck.define_method(:full?) { super() }
  end

  def make_user(name)
    User.create!(email: "#{name}@race.test", display_name: name, password: "a-long-password-1")
  end

  # Runs the block once per item, all threads released at the same moment, each with its own connection.
  def in_parallel(items)
    start = Queue.new
    threads = items.map do |item|
      Thread.new do
        start.pop
        ActiveRecord::Base.connection_pool.with_connection { yield item }
      end
    end
    items.size.times { start << true }
    threads.map(&:value)
  end
end
