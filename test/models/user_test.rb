require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build(**attrs)
    User.new({ email: "bob@example.com", display_name: "Bob", password: "a-long-password-1" }.merge(attrs))
  end

  test "valid user" do
    assert build.valid?
  end

  test "password must be at least 12 characters" do
    assert_not build(password: "short").valid?
  end

  test "email is normalized and unique" do
    assert_equal "bob@example.com", build(email: "  BOB@Example.com ").email
    assert_not build(email: "ALICE@example.com").valid?
  end

  test "password is stored hashed" do
    user = build.tap(&:save!)
    assert_not_equal "a-long-password-1", user.password_digest
  end
end
