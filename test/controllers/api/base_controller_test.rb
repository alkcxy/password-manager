require "test_helper"

module Api
  class TestPingController < BaseController
    def ping
      render json: { user_id: @current_user.id.to_s }
    end
  end
end

class Api::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.routes.draw do
      namespace :api do
        get "test_ping/ping", to: "test_ping#ping"
      end
    end

    @user  = User.create!(name: "Bob", email: "bob@example.com",
                          password: "password123", password_confirmation: "password123")
    @token = ApiToken.generate_for(@user)
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "returns 200 with valid token" do
    get "/api/test_ping/ping",
        headers: { "Authorization" => "Bearer #{@token.token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @user.id.to_s, json["user_id"]
  end

  test "returns 401 when Authorization header is absent" do
    get "/api/test_ping/ping"
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "returns 401 when token does not exist" do
    get "/api/test_ping/ping",
        headers: { "Authorization" => "Bearer nonexistenttoken000000000000000" }
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "returns 401 when token is expired" do
    @token.update!(expires_at: 1.minute.ago)
    get "/api/test_ping/ping",
        headers: { "Authorization" => "Bearer #{@token.token}" }
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_includes json["error"], "expired"
  end

  test "returns 401 when Authorization uses wrong scheme" do
    get "/api/test_ping/ping",
        headers: { "Authorization" => "Basic dXNlcjpwYXNz" }
    assert_response :unauthorized
  end
end
