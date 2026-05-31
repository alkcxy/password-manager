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

  test "copy username from index writes correct value to clipboard" do
    visit credentials_url
    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS

    find('[aria-label="Copia username"]', match: :first).click

    assert_equal @credential.username, page.evaluate_script('window._clipboard[0]')
  end

  test "copy username button shows checkmark feedback then reverts" do
    visit credentials_url
    page.execute_script(<<~JS)
      navigator.clipboard = { writeText: () => Promise.resolve() };
    JS

    btn = find('[aria-label="Copia username"]', match: :first)
    btn.click
    assert_text "✓"
    sleep 2.1
    assert_no_text "✓"
  end

  test "copy password from index writes correct value to clipboard without revealing it" do
    visit credentials_url
    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS

    find('[aria-label="Copia password"]', match: :first).click
    find('[aria-label="Copia password"]', text: "✓", match: :first)

    assert_equal "secret", page.evaluate_script('window._clipboard[0]')
    assert_no_text "secret"
  end

  test "copy username from show view writes correct value to clipboard" do
    visit credential_url(@credential)
    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS

    find('[aria-label="Copia username"]').click

    assert_equal @credential.username, page.evaluate_script('window._clipboard[0]')
  end

  test "copy password from show view writes correct value to clipboard" do
    visit credential_url(@credential)
    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS

    find('[aria-label="Copia password"]').click
    find('[aria-label="Copia password"]', text: "✓")

    assert_equal "secret", page.evaluate_script('window._clipboard[0]')
  end
end
