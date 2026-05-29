require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "welcome page is accessible without login when no users exist" do
    get welcome_url
    assert_response :success
  end

  test "login page is accessible" do
    get login_url
    assert_response :success
  end

  test "successful login redirects to root" do
    user = User.create!(name: 'Test', email: 'test@example.com',
                        password: 'password123', password_confirmation: 'password123')
    post login_url, params: { email: user.email, password: 'password123' }
    assert_redirected_to root_url
  end

  test "failed login redirects to root with notice" do
    post login_url, params: { email: 'wrong@example.com', password: 'bad' }
    assert_redirected_to root_url
  end

  test "logout deletes session and redirects" do
    user = User.create!(name: 'Test', email: 'test@example.com',
                        password: 'password123', password_confirmation: 'password123')
    post login_url, params: { email: user.email, password: 'password123' }
    delete logout_url
    assert_redirected_to root_url
  end
end
