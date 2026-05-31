require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Test User", email: "test@example.com",
                         password: "password123", password_confirmation: "password123")
    visit login_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_on "Login"
    assert_text "Benvenuto"
  end

  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: "Utenti"
  end

  test "creating a User" do
    visit users_url
    click_on "Nuovo Utente"

    fill_in "Email", with: "new@example.com"
    fill_in "Name", with: "New User"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    find('[type="submit"]').click

    assert_text "User was successfully created"
  end

  test "updating a User" do
    visit edit_user_url(@user)

    fill_in "Name", with: "Updated Name"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    find('[type="submit"]').click

    assert_text "User was successfully updated"
  end

  test "destroying a User" do
    extra = User.create!(name: "To Delete", email: "del@example.com",
                         password: "password123", password_confirmation: "password123")
    visit users_url
    page.accept_confirm do
      click_on "Cancella", match: :first
    end

    assert_text "User was successfully destroyed"
  end
end
