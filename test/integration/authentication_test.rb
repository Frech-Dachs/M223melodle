require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "dashboard requires login" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "registration logs the user in" do
    assert_difference "User.count", 1 do
      post users_path, params: { user: { email: "new@example.com", display_name: "New",
                                         password: "a-long-password-1", password_confirmation: "a-long-password-1" } }
    end
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
  end

  test "registration with invalid data shows errors" do
    assert_no_difference "User.count" do
      post users_path, params: { user: { email: "bad", display_name: "", password: "short", password_confirmation: "short" } }
    end
    assert_response :unprocessable_entity
  end

  test "login with valid credentials" do
    post session_path, params: { email: "alice@example.com", password: "correct-horse-battery" }
    assert_redirected_to dashboard_path
  end

  test "login with wrong password is rejected" do
    post session_path, params: { email: "alice@example.com", password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "logout ends the session" do
    post session_path, params: { email: "alice@example.com", password: "correct-horse-battery" }
    delete session_path
    get dashboard_path
    assert_redirected_to new_session_path
  end
end
