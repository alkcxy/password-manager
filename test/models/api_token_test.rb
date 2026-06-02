require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Alice", email: "alice@example.com",
                         password: "password123", password_confirmation: "password123")
  end

  test "generate_for creates a persisted token for the user" do
    token = ApiToken.generate_for(@user)
    assert token.persisted?
    assert_equal @user, token.user
  end

  test "generated token is a 64-character hex string" do
    token = ApiToken.generate_for(@user)
    assert_match(/\A[0-9a-f]{64}\z/, token.token)
  end

  test "expires_at is set to TTL_DAYS days from now" do
    travel_to Time.current do
      token = ApiToken.generate_for(@user)
      expected = ApiToken::TTL_DAYS.days.from_now
      assert_in_delta expected.to_f, token.expires_at.to_f, 1.0
    end
  end

  test "expired? returns false for a fresh token" do
    token = ApiToken.generate_for(@user)
    assert_not token.expired?
  end

  test "expired? returns true for a token past expires_at" do
    token = ApiToken.generate_for(@user)
    token.update!(expires_at: 1.day.ago)
    assert token.expired?
  end

  test "token field is required" do
    token = ApiToken.new(user: @user, expires_at: 1.day.from_now)
    assert_not token.valid?
    assert token.errors[:token].any?
  end

  test "expires_at field is required" do
    token = ApiToken.new(user: @user, token: "abc")
    assert_not token.valid?
    assert token.errors[:expires_at].any?
  end

  test "token must be unique" do
    existing = ApiToken.generate_for(@user)
    duplicate = ApiToken.new(token: existing.token, user: @user, expires_at: 1.day.from_now)
    assert_not duplicate.valid?
  end

  test "valid scope excludes expired tokens" do
    ApiToken.generate_for(@user)
    expired = ApiToken.generate_for(@user)
    expired.update!(expires_at: 1.hour.ago)
    assert_equal 1, ApiToken.valid.count
  end

  test "valid scope includes non-expired tokens" do
    2.times { ApiToken.generate_for(@user) }
    assert_equal 2, ApiToken.valid.count
  end

  test "TTL_DAYS is a positive integer" do
    assert_kind_of Integer, ApiToken::TTL_DAYS
    assert_operator ApiToken::TTL_DAYS, :>, 0
  end
end
