require "test_helper"

class Api::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # POST /api/sessions

  test "returns token when credentials are valid" do
    post "/api/sessions", params: { email: @user.email, password: "password123" }, as: :json
    assert_response :created
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert json["expires_at"].present?
    assert ApiToken.where(token: json["token"]).exists?
  end

  test "returns 401 when password is wrong" do
    post "/api/sessions", params: { email: @user.email, password: "wrongpassword" }, as: :json
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "returns 401 when email does not exist" do
    post "/api/sessions", params: { email: "nobody@example.com", password: "password123" }, as: :json
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  # DELETE /api/sessions/:token

  test "destroys token and returns 204" do
    api_token = ApiToken.generate_for(@user)
    delete "/api/sessions/#{api_token.token}"
    assert_response :no_content
    assert_not ApiToken.where(token: api_token.token).exists?
  end

  test "returns 404 when token does not exist" do
    delete "/api/sessions/nonexistenttoken000000000000000000000000000000000000000000000000"
    assert_response :not_found
    json = JSON.parse(response.body)
    assert json["error"].present?
  end
end
