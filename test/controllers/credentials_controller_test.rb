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

  test "index shows page 1 as active in paginator" do
    26.times { |i| Credential.create!(name: "Cred #{i}", username: "u", password: "p", url: "https://x.com", note: "", user: @user) }
    get credentials_url
    assert_response :success
    assert_select "li.page-item.active a.page-link", text: "1"
  end

  test "index shows page 2 as active when requested" do
    26.times { |i| Credential.create!(name: "Cred #{i}", username: "u", password: "p", url: "https://x.com", note: "", user: @user) }
    get credentials_url, params: { page: 2 }
    assert_response :success
    assert_select "li.page-item.active a.page-link", text: "2"
  end

  test "index renders Bootstrap pagination markup" do
    26.times { |i| Credential.create!(name: "Cred #{i}", username: "u", password: "p", url: "https://x.com", note: "", user: @user) }
    get credentials_url
    assert_select "ul.pagination"
    assert_select "li.page-item"
  end

  test "edit form renders decrypted password in input value" do
    get edit_credential_url(@credential)
    assert_select "input[name='credential[password]'][value='secret']"
  end

  test "update preserves existing password when blank password submitted" do
    patch credential_url(@credential), params: { credential: { name: 'GitHub Updated',
                                                                username: @credential.username,
                                                                password: '',
                                                                url: @credential.url,
                                                                note: '' } }
    assert_redirected_to credential_url(@credential)
    assert_equal "secret", @credential.reload.password
  end

  test "copy_password returns JSON with decrypted password" do
    get copy_password_credential_url(@credential), headers: { "Accept" => "application/json" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "secret", json["password"]
  end

  test "copy_password returns 406 for non-JSON request" do
    get copy_password_credential_url(@credential)
    assert_response :not_acceptable
  end

  test "copy_password requires authentication" do
    delete logout_url
    get copy_password_credential_url(@credential), headers: { "Accept" => "application/json" }
    assert_redirected_to "/welcome"
  end

  test "copy_password returns 404 for another user's credential" do
    other = User.create!(name: "Other", email: "other@example.com",
                         password: "password123", password_confirmation: "password123")
    other_cred = Credential.create!(name: "Other Cred", username: "x",
                                    password: "topsecret", url: "https://other.com",
                                    note: "", user: other)
    get copy_password_credential_url(other_cred), headers: { "Accept" => "application/json" }
    assert_response :not_found
  end
end
