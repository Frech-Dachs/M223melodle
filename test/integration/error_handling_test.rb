require "test_helper"

class ErrorHandlingTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = User.create!(email: "bob@example.com", display_name: "Bob", password: "a-long-password-1")
  end

  def login(user, password = "a-long-password-1")
    post session_path, params: { email: user.email, password: password }
  end

  test "unknown record shows the friendly 404 page without technical details" do
    login(@bob)
    get group_path(id: 999_999)
    assert_response :not_found
    assert_match(/Seite nicht gefunden/, response.body)
    assert_no_match(/ActiveRecord|Rails\.root|backtrace/i, response.body)
  end

  test "role and points cannot be set through request parameters" do
    group = Group.create_with_host!({ name: "G", member_limit: 5 }, @alice)
    login(@bob)
    post join_path, params: { invite_code: group.invite_code, role: "host", membership: { role: "host" } }
    assert Membership.find_by(user: @bob, group: group).player?
    assert_equal 0, Score.find_by(user: @bob, group: group).total_points
  end

  test "forms keep the entered values when validation fails" do
    login(@alice, "correct-horse-battery")
    post groups_path, params: { group: { name: "", member_limit: 7 } }
    assert_response :unprocessable_entity
    assert_select "input[name='group[member_limit]'][value='7']"
  end

  test "state changing requests without CSRF token are rejected when protection is on" do
    ActionController::Base.allow_forgery_protection = true
    post session_path, params: { email: @alice.email, password: "correct-horse-battery" }
    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
