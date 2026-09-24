require "test_helper"

class ProfileTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  def login
    post session_path, params: { email: @user.email, password: "correct-horse-battery" }
  end

  test "profile requires login" do
    get profile_path
    assert_redirected_to new_session_path
  end

  test "display name can be changed" do
    login
    patch profile_path, params: { user: { display_name: "Alice B", email: @user.email } }
    assert_redirected_to profile_path
    assert_equal "Alice B", @user.reload.display_name
  end

  test "blank display name is rejected with 422" do
    login
    patch profile_path, params: { user: { display_name: "", email: @user.email } }
    assert_response :unprocessable_entity
  end

  test "email change is confirmed through the mailed link" do
    login
    assert_emails 1 do
      patch profile_path, params: { user: { display_name: "Alice", email: "New@Example.com" } }
    end
    assert_equal "alice@example.com", @user.reload.email
    assert_equal "new@example.com", @user.unconfirmed_email

    get email_confirmation_path(@user.generate_token_for(:email_confirmation))
    assert_equal "new@example.com", @user.reload.email
    assert_nil @user.unconfirmed_email
  end

  test "email change to a taken address is rejected" do
    User.create!(email: "taken@example.com", display_name: "T", password: "a-long-password-1")
    login
    assert_no_emails do
      patch profile_path, params: { user: { display_name: "Alice", email: "taken@example.com" } }
    end
    assert_response :unprocessable_entity
    assert_nil @user.reload.unconfirmed_email
  end

  test "invalid confirmation token is refused" do
    get email_confirmation_path("garbage")
    assert_redirected_to root_path
  end

  test "token becomes invalid when another address is requested" do
    @user.request_email_change!("one@example.com")
    token = @user.generate_token_for(:email_confirmation)
    @user.request_email_change!("two@example.com")
    get email_confirmation_path(token)
    assert_equal "alice@example.com", @user.reload.email
  end

  test "password change requires the current password" do
    login
    patch password_path, params: { current_password: "wrong", user: { password: "another-long-pass-1", password_confirmation: "another-long-pass-1" } }
    assert_response :unprocessable_entity
    assert @user.reload.authenticate("correct-horse-battery")
  end

  test "password change with valid data works and enforces length" do
    login
    patch password_path, params: { current_password: "correct-horse-battery", user: { password: "short", password_confirmation: "short" } }
    assert_response :unprocessable_entity
    patch password_path, params: { current_password: "correct-horse-battery", user: { password: "another-long-pass-1", password_confirmation: "another-long-pass-1" } }
    assert_redirected_to profile_path
    assert @user.reload.authenticate("another-long-pass-1")
  end
end
