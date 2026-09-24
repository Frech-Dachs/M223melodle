require "test_helper"

class GroupsTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = User.create!(email: "bob@example.com", display_name: "Bob", password: "a-long-password-1")
    @carol = User.create!(email: "carol@example.com", display_name: "Carol", password: "a-long-password-1")
  end

  def login(user, password = "a-long-password-1")
    post session_path, params: { email: user.email, password: password }
  end

  test "creating a group makes the creator host with a score" do
    login(@alice, "correct-horse-battery")
    assert_difference [ "Group.count", "Membership.count", "Score.count" ], 1 do
      post groups_path, params: { group: { name: "Friends", member_limit: 5 } }
    end
    group = Group.last
    assert_redirected_to group_path(group)
    assert Membership.find_by(user: @alice, group: group).host?
  end

  test "invalid group keeps the form and creates nothing" do
    login(@alice, "correct-horse-battery")
    assert_no_difference [ "Group.count", "Membership.count" ] do
      post groups_path, params: { group: { name: "", member_limit: 5 } }
    end
    assert_response :unprocessable_entity
  end

  test "joining with a code makes a player with a score" do
    group = Group.create_with_host!({ name: "G", member_limit: 3 }, @alice)
    login(@bob)
    post join_path, params: { invite_code: " #{group.invite_code.downcase} " }
    assert_redirected_to group_path(group)
    assert Membership.find_by(user: @bob, group: group).player?
    assert Score.exists?(user: @bob, group: group)
  end

  test "unknown code is rejected" do
    login(@bob)
    post join_path, params: { invite_code: "NOPE1234" }
    assert_response :unprocessable_entity
  end

  test "joining a full group is rejected" do
    group = Group.create_with_host!({ name: "G", member_limit: 2 }, @alice)
    Group.join!(group.invite_code, @bob)
    login(@carol)
    assert_no_difference "Membership.count" do
      post join_path, params: { invite_code: group.invite_code }
    end
    assert_response :unprocessable_entity
  end

  test "joining twice is rejected" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @alice)
    assert_raises(Group::AlreadyMember) { Group.join!(group.invite_code, @alice) }
  end

  test "non-members get a 404 for a group" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @alice)
    login(@bob)
    get group_path(group)
    assert_response :not_found
  end

  test "host can remove a player, score included" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @alice)
    Group.join!(group.invite_code, @bob)
    login(@alice, "correct-horse-battery")
    membership = group.memberships.find_by(user: @bob)
    assert_difference "Membership.count", -1 do
      delete group_membership_path(group, membership)
    end
    assert_not Score.exists?(user: @bob, group: group)
  end

  test "player cannot remove members" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @alice)
    Group.join!(group.invite_code, @bob)
    login(@bob)
    assert_no_difference "Membership.count" do
      delete group_membership_path(group, group.memberships.find_by(user: @alice))
    end
  end

  test "host cannot remove themselves" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @alice)
    login(@alice, "correct-horse-battery")
    assert_no_difference "Membership.count" do
      delete group_membership_path(group, group.memberships.find_by(user: @alice))
    end
  end

  test "dashboard lists my groups" do
    Group.create_with_host!({ name: "Listed", member_limit: 5 }, @alice)
    login(@alice, "correct-horse-battery")
    get dashboard_path
    assert_select "a", "Listed"
  end
end
