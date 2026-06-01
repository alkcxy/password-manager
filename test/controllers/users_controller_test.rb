require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: 'Test User', email: 'test@example.com',
                         password: 'password123', password_confirmation: 'password123')
    post login_url, params: { email: @user.email, password: 'password123' }
  end

  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post users_url, params: { user: { name: 'New User', email: 'new@example.com',
                                        password: 'password123',
                                        password_confirmation: 'password123' } }
    end
    assert_redirected_to user_url(User.last)
  end

  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch user_url(@user), params: { user: { name: 'Updated Name', email: @user.email,
                                             password: 'password123',
                                             password_confirmation: 'password123' } }
    assert_redirected_to user_url(@user)
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete user_url(@user)
    end
    assert_redirected_to users_url
  end

  test "index shows page 1 as active in paginator" do
    25.times { |i| User.create!(name: "User #{i}", email: "u#{i}@example.com", password: "password123", password_confirmation: "password123") }
    get users_url
    assert_response :success
    assert_select "li.page-item.active a.page-link", text: "1"
  end

  test "index shows page 2 as active when requested" do
    25.times { |i| User.create!(name: "User #{i}", email: "u#{i}@example.com", password: "password123", password_confirmation: "password123") }
    get users_url, params: { page: 2 }
    assert_response :success
    assert_select "li.page-item.active a.page-link", text: "2"
  end

  test "index renders Bootstrap pagination markup" do
    25.times { |i| User.create!(name: "User #{i}", email: "u#{i}@example.com", password: "password123", password_confirmation: "password123") }
    get users_url
    assert_select "ul.pagination"
    assert_select "li.page-item"
  end

  # ===== Issue #50: Bootstrap Icons =====

  test "index: action buttons grouped in a single text-nowrap cell with icons" do
    get users_url
    assert_select "td.text-nowrap a[aria-label='Visualizza'] i.bi-eye"
    assert_select "td.text-nowrap a[aria-label='Modifica'] i.bi-pencil"
    assert_select "td.text-nowrap a[aria-label='Cancella'] i.bi-trash"
  end

  test "index: new user button has person-plus icon" do
    get users_url
    assert_select "a[href='#{new_user_path}'] i.bi-person-plus"
  end

  test "show: edit button has pencil icon and users link has people icon" do
    get user_url(@user)
    assert_select "a[href='#{edit_user_path(@user)}'] i.bi-pencil"
    assert_select "a[href='#{users_path}'] i.bi-people"
  end
end
