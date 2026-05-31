require "application_system_test_case"

class CredentialsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Test User", email: "test@example.com",
                         password: "password123", password_confirmation: "password123")
    @credential = Credential.create!(name: "GitHub", username: "testuser",
                                     password: "secret", url: "https://github.com",
                                     note: "Personal account", user: @user)
    visit login_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_on "Login"
    assert_text "Benvenuto"
  end

  test "visiting the index" do
    visit credentials_url
    assert_selector "h1", text: "Credenziali"
  end

  test "creating a Credential" do
    visit credentials_url
    click_on "Nuova Credenziale"

    fill_in "Name", with: "GitLab"
    fill_in "Note", with: ""
    fill_in "Password", with: "secret2"
    fill_in "Url", with: "https://gitlab.com"
    fill_in "Username", with: "testuser"
    find('[type="submit"]').click

    assert_text "Credential was successfully created"
  end

  test "updating a Credential" do
    visit edit_credential_url(@credential)

    fill_in "Name", with: "GitHub Updated"
    find('[type="submit"]').click

    assert_text "Credential was successfully updated"
  end

  test "destroying a Credential" do
    visit credentials_url
    page.accept_confirm do
      click_on "Cancella", match: :first
    end

    assert_text "Credential was successfully destroyed"
  end
end
