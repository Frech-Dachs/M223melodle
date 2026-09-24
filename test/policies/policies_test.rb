require "test_helper"

class PoliciesTest < ActiveSupport::TestCase
  setup do
    @host = users(:alice)
    @player = User.create!(email: "p@example.com", display_name: "P", password: "a-long-password-1")
    @outsider = User.create!(email: "o@example.com", display_name: "O", password: "a-long-password-1")
    @group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    Group.join!(@group.invite_code, @player)
    @other_group = Group.create_with_host!({ name: "Other", member_limit: 5 }, @outsider)
    @song = @group.songs.create!(title: "T", artist: "A", audio_url: "/a.mp3", added_by: @host)
    @round = @group.rounds.build(song: @song, started_by: @host)
  end

  test "group: members see it, outsiders do not, only host manages members" do
    assert GroupPolicy.new(@host, @group).show?
    assert GroupPolicy.new(@player, @group).show?
    assert_not GroupPolicy.new(@outsider, @group).show?
    assert GroupPolicy.new(@host, @group).manage_members?
    assert_not GroupPolicy.new(@player, @group).manage_members?
    assert_not GroupPolicy.new(@outsider, @group).manage_members?
  end

  test "group scope only returns own groups" do
    assert_equal [ @group ], GroupPolicy::Scope.new(@player, Group).resolve.to_a
    assert_equal [ @other_group ], GroupPolicy::Scope.new(@outsider, Group).resolve.to_a
  end

  test "membership: host removes others but not self" do
    host_membership = @group.memberships.find_by(user: @host)
    player_membership = @group.memberships.find_by(user: @player)
    assert MembershipPolicy.new(@host, player_membership).destroy?
    assert_not MembershipPolicy.new(@host, host_membership).destroy?
    assert_not MembershipPolicy.new(@player, host_membership).destroy?
    assert_not MembershipPolicy.new(@outsider, player_membership).destroy?
  end

  test "song: members list, only host changes" do
    assert SongPolicy.new(@player, @song).index?
    assert_not SongPolicy.new(@outsider, @song).index?
    assert SongPolicy.new(@host, @song).create?
    assert SongPolicy.new(@host, @song).destroy?
    assert_not SongPolicy.new(@player, @song).create?
    assert_not SongPolicy.new(@player, @song).destroy?
    assert_not SongPolicy.new(@outsider, @song).destroy?
  end

  test "round: only host starts, members play, outsiders nothing" do
    assert RoundPolicy.new(@host, @round).create?
    assert_not RoundPolicy.new(@player, @round).create?
    assert_not RoundPolicy.new(@outsider, @round).create?
    assert RoundPolicy.new(@player, @round).guess?
    assert RoundPolicy.new(@player, @round).show?
    assert_not RoundPolicy.new(@outsider, @round).guess?
    assert_not RoundPolicy.new(@outsider, @round).show?
  end

  test "role is per group" do
    assert GroupPolicy.new(@outsider, @other_group).manage_members?
    assert_not GroupPolicy.new(@outsider, @group).manage_members?
  end
end
