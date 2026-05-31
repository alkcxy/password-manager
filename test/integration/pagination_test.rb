require "test_helper"

class PaginationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Test User", email: "test@example.com",
                         password: "password123", password_confirmation: "password123")
    post login_url, params: { email: @user.email, password: "password123" }
  end

  # --- Credentials ---

  test "credentials: paginator hidden when records fit on one page" do
    3.times { |i| Credential.create!(name: "C#{i}", username: "u", password: "p", url: "https://x.com", note: "", user: @user) }
    get credentials_url
    assert_select "ul.pagination", count: 0
  end

  test "credentials: Bootstrap paginator present on page 1 of 2" do
    26.times { |i| Credential.create!(name: "Cred #{i}", username: "u", password: "p", url: "https://x.com", note: "", user: @user) }
    get credentials_url
    assert_select "ul.pagination.pagination-sm"
    assert_select "li.page-item.active a.page-link", text: "1"
  end

  test "credentials: page 2 shows correct active page" do
    26.times { |i| Credential.create!(name: "Cred #{i}", username: "u", password: "p", url: "https://x.com", note: "", user: @user) }
    get credentials_url, params: { page: 2 }
    assert_select "li.page-item.active a.page-link", text: "2"
  end

  test "credentials: page_entries_info label present in Italian" do
    26.times { |i| Credential.create!(name: "Cred #{i}", username: "u", password: "p", url: "https://x.com", note: "", user: @user) }
    get credentials_url
    assert_select ".text-muted.small" do
      assert_select "[class~=small]"
    end
    assert_match(/credenziali/, response.body)
    assert_match(/Visualizzando/, response.body)
  end

  # --- Users ---

  test "users: paginator hidden when records fit on one page" do
    get users_url
    assert_select "ul.pagination", count: 0
  end

  test "users: Bootstrap paginator present on page 1 of 2" do
    25.times { |i| User.create!(name: "User #{i}", email: "u#{i}@example.com", password: "password123", password_confirmation: "password123") }
    get users_url
    assert_select "ul.pagination.pagination-sm"
    assert_select "li.page-item.active a.page-link", text: "1"
  end

  test "users: page 2 shows correct active page" do
    25.times { |i| User.create!(name: "User #{i}", email: "u#{i}@example.com", password: "password123", password_confirmation: "password123") }
    get users_url, params: { page: 2 }
    assert_select "li.page-item.active a.page-link", text: "2"
  end

  test "users: page_entries_info label present in Italian" do
    25.times { |i| User.create!(name: "User #{i}", email: "u#{i}@example.com", password: "password123", password_confirmation: "password123") }
    get users_url
    assert_match(/utenti/, response.body)
    assert_match(/Visualizzando/, response.body)
  end
end
