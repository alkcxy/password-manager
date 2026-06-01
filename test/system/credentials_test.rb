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
      find('[aria-label="Cancella"]', match: :first).click
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
    assert_selector '[aria-label="Copia username"] i.bi-clipboard-check', match: :first
    assert_no_selector '[aria-label="Copia username"] i.bi-clipboard-check', match: :first, wait: 5
    assert_selector '[aria-label="Copia username"] i.bi-clipboard', match: :first
  end

  test "copy password from index writes correct value to clipboard without revealing it" do
    visit credentials_url
    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS

    find('[aria-label="Copia password"]', match: :first).click
    assert_selector '[aria-label="Copia password"] i.bi-clipboard-check', match: :first

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

  test "edit form shows decrypted password and preserves it when saved without changes" do
    visit edit_credential_url(@credential)
    assert_field "Password", with: "secret"

    fill_in "Name", with: "GitHub Renamed"
    find('[type="submit"]').click
    assert_text "Credential was successfully updated"

    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS
    find('[aria-label="Copia password"]').click
    assert_selector '[aria-label="Copia password"] i.bi-clipboard-check'
    assert_equal "secret", page.evaluate_script('window._clipboard[0]')
  end

  test "copy password from show view writes correct value to clipboard without revealing it" do
    visit credential_url(@credential)
    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS

    find('[aria-label="Copia password"]').click
    assert_selector '[aria-label="Copia password"] i.bi-clipboard-check'

    assert_equal "secret", page.evaluate_script('window._clipboard[0]')
    assert_no_text "secret"
  end

  test "copy password shows error icon when fetch fails from index" do
    visit credentials_url
    page.execute_script(<<~JS)
      window.fetch = () => Promise.reject(new Error('network error'))
    JS

    find('[aria-label="Copia password"]', match: :first).click
    assert_selector '[aria-label="Copia password"] i.bi-x-circle', match: :first
    assert_no_selector '[aria-label="Copia password"] i.bi-x-circle', match: :first, wait: 5
  end

  test "copy password shows error icon when fetch fails from show view" do
    visit credential_url(@credential)
    page.execute_script(<<~JS)
      window.fetch = () => Promise.reject(new Error('network error'))
    JS

    find('[aria-label="Copia password"]').click
    assert_selector '[aria-label="Copia password"] i.bi-x-circle'
    assert_no_selector '[aria-label="Copia password"] i.bi-x-circle', wait: 5
  end

  test "password field is masked by default in edit form" do
    visit edit_credential_url(@credential)
    assert_equal "password", find("#credential_password")[:type]
  end

  test "toggle button reveals and re-masks password in edit form" do
    visit edit_credential_url(@credential)
    find('[aria-label="Mostra/nascondi password"]').click
    assert_equal "text", find("#credential_password")[:type]

    find('[aria-label="Mostra/nascondi password"]').click
    assert_equal "password", find("#credential_password")[:type]
  end

  # ===== Issue #50: Bootstrap Icons =====

  test "copy url from index writes correct value to clipboard" do
    visit credentials_url
    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS

    find('[aria-label="Copia url"]', match: :first).click

    assert_equal @credential.url, page.evaluate_script('window._clipboard[0]')
  end

  test "clipboard icon shows bi-clipboard-check on copy then reverts to bi-clipboard" do
    visit credentials_url
    page.execute_script(<<~JS)
      navigator.clipboard = { writeText: () => Promise.resolve() };
    JS

    find('[aria-label="Copia username"]', match: :first).click
    assert_selector '[aria-label="Copia username"] i.bi-clipboard-check', match: :first
    assert_no_selector '[aria-label="Copia username"] i.bi-clipboard-check', match: :first, wait: 5
    assert_selector '[aria-label="Copia username"] i.bi-clipboard', match: :first
  end

  test "clicking note button opens popover with note content" do
    visit credentials_url
    find("button[data-bs-toggle='popover']").click
    assert_selector ".popover-body", text: @credential.note
  end

  test "clicking a second note button closes the first popover" do
    cred2 = Credential.create!(name: "Bitbucket", username: "u2", password: "pw",
                               url: "https://bitbucket.com", note: "Work account", user: @user)
    visit credentials_url

    first_btn = find("button[data-bs-content='#{@credential.note}']")
    second_btn = find("button[data-bs-content='#{cred2.note}']")

    first_btn.click
    assert_selector ".popover-body", text: @credential.note

    second_btn.click
    assert_selector ".popover-body", text: cred2.note
    assert_no_selector ".popover-body", text: @credential.note
  end

  test "note button not shown for credentials without a note" do
    Credential.create!(name: "No Note", username: "u2", password: "pw",
                       url: "https://x.com", note: "", user: @user)
    visit credentials_url
    assert_selector "button[data-bs-toggle='popover']", count: 1
  end

  # ===== Cloudflare email obfuscation protection =====

  test "reveals password containing @ as plain text without obfuscation" do
    Credential.create!(name: "At Sign", username: "u", password: "p@ssw0rd",
                       url: "https://x.com", note: "", user: @user)
    visit credentials_url
    within("tr", text: "At Sign") do
      find('[aria-label="Mostra"]').click
    end
    assert_selector "code", text: "p@ssw0rd"
  end

  test "copies password with @ to clipboard correctly" do
    Credential.create!(name: "At Sign", username: "u", password: "p@ssw0rd",
                       url: "https://x.com", note: "", user: @user)
    visit credentials_url
    page.execute_script(<<~JS)
      window._clipboard = [];
      navigator.clipboard = { writeText: t => { window._clipboard.push(t); return Promise.resolve(); } };
    JS
    within("tr", text: "At Sign") do
      find('[aria-label="Copia password"]').click
      assert_selector '[aria-label="Copia password"] i.bi-clipboard-check'
    end
    assert_equal "p@ssw0rd", page.evaluate_script('window._clipboard[0]')
  end
end
