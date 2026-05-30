require 'test_helper'

class CredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: 'Test User', email: 'test@example.com',
                         password: 'password123', password_confirmation: 'password123')
    @credential = Credential.create!(name: 'GitHub', username: 'testuser',
                                     password: 'secret', url: 'https://github.com',
                                     note: 'Personal account', user: @user)
    post login_url, params: { email: @user.email, password: 'password123' }
  end

  test "should get index" do
    get credentials_url
    assert_response :success
  end

  test "should get new" do
    get new_credential_url
    assert_response :success
  end

  test "should create credential" do
    assert_difference('Credential.count') do
      post credentials_url, params: { credential: { name: 'GitLab', username: 'user',
                                                     password: 'pass', url: 'https://gitlab.com',
                                                     note: '' } }
    end
    assert_redirected_to credential_url(Credential.last)
  end

  test "should show credential" do
    get credential_url(@credential)
    assert_response :success
  end

  test "should get edit" do
    get edit_credential_url(@credential)
    assert_response :success
  end

  test "should update credential" do
    patch credential_url(@credential), params: { credential: { name: 'GitHub Updated',
                                                                username: @credential.username,
                                                                password: 'newpass',
                                                                url: @credential.url,
                                                                note: '' } }
    assert_redirected_to credential_url(@credential)
  end

  test "should destroy credential" do
    assert_difference('Credential.count', -1) do
      delete credential_url(@credential)
    end
    assert_redirected_to credentials_url
  end
end
