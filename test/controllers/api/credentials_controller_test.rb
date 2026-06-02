require "test_helper"

class Api::CredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @other_user = User.create!(
      name: "Bob",
      email: "bob@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @token = ApiToken.generate_for(@user)
    @other_token = ApiToken.generate_for(@other_user)

    @github_cred = Credential.create!(
      name: "GitHub",
      username: "alice",
      password: "secret123",
      url: "https://github.com/login",
      user: @user
    )
    @gitlab_cred = Credential.create!(
      name: "GitLab",
      username: "alice",
      password: "secret456",
      url: "https://gitlab.com/login",
      user: @user
    )
    @other_cred = Credential.create!(
      name: "GitHub Bob",
      username: "bob",
      password: "bobsecret",
      url: "https://github.com/login",
      user: @other_user
    )
  end

  # GET /api/credentials?domain=

  test "index returns 401 without token" do
    get "/api/credentials", params: { domain: "github.com" }, as: :json
    assert_response :unauthorized
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "index returns credentials matching domain" do
    get "/api/credentials", params: { domain: "github.com" },
        headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal @github_cred.id.to_s, json.first["id"]
    assert_equal "GitHub", json.first["name"]
    assert_equal "alice", json.first["username"]
    assert json.first["url"].present?
    assert_nil json.first["password"]
  end

  test "index returns empty array when no credentials match domain" do
    get "/api/credentials", params: { domain: "twitter.com" },
        headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :ok
    assert_equal [], JSON.parse(response.body)
  end

  test "index does not return other users credentials" do
    get "/api/credentials", params: { domain: "github.com" },
        headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    ids = json.map { |c| c["id"] }
    assert_not_includes ids, @other_cred.id.to_s
  end

  test "index does not match superdomain (mygithub.com must not match github.com)" do
    Credential.create!(
      name: "MyGitHub",
      username: "alice",
      password: "fake",
      url: "https://mygithub.com/login",
      user: @user
    )
    get "/api/credentials", params: { domain: "github.com" },
        headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json.none? { |c| c["name"] == "MyGitHub" }
  end

  test "index without domain param returns all user credentials" do
    get "/api/credentials",
        headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json.length
    assert json.none? { |c| c["password"].present? }
  end

  # GET /api/credentials/:id

  test "show returns 401 without token" do
    get "/api/credentials/#{@github_cred.id}", as: :json
    assert_response :unauthorized
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "show returns credential with password for owner" do
    get "/api/credentials/#{@github_cred.id}",
        headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @github_cred.id.to_s, json["id"]
    assert_equal "GitHub", json["name"]
    assert_equal "alice", json["username"]
    assert_equal "secret123", json["password"]
    assert json["url"].present?
  end

  test "show returns 404 when credential belongs to another user" do
    get "/api/credentials/#{@other_cred.id}",
        headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :not_found
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "show returns 404 for nonexistent id" do
    get "/api/credentials/000000000000000000000000",
        headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :not_found
  end

  # POST /api/credentials

  test "create returns 401 without token" do
    post "/api/credentials",
         params: { name: "Test", username: "user", password: "pass", url: "https://test.com" },
         as: :json
    assert_response :unauthorized
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "create returns 201 with valid params" do
    assert_difference -> { Credential.where(user: @user).count }, 1 do
      post "/api/credentials",
           params: { name: "Twitter", username: "alice", password: "twitterpass", url: "https://twitter.com" },
           headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert json["id"].present?
    assert_equal "Twitter", json["name"]
    assert_nil json["password"]
  end

  test "create returns 422 when required params are missing" do
    post "/api/credentials",
         params: { name: "NoUrl", username: "alice", password: "pass" },
         headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "application/json; charset=utf-8", response.content_type
    json = JSON.parse(response.body)
    assert json["errors"].present?
  end

  test "create does not write to DB when params are invalid" do
    assert_no_difference -> { Credential.count } do
      post "/api/credentials",
           params: { username: "alice", password: "pass", url: "https://test.com" },
           headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
    end
  end
end
