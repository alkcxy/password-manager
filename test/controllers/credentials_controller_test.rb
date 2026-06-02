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

  test "edit form: toggle button precedes password input in DOM" do
    get edit_credential_url(@credential)
    assert_match(/Mostra\/nascondi password.*credential\[password\]/m, response.body)
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

  # ===== Issue #50: Bootstrap Icons =====

  test "index: navbar shows Bootstrap icon buttons" do
    get credentials_url
    assert_select "a.btn i.bi-house"
    assert_select "a.btn i.bi-key"
    assert_select "a.btn i.bi-people"
    assert_select "a.btn i.bi-box-arrow-right"
  end

  test "index: table is wrapped in table-responsive div" do
    get credentials_url
    assert_select "div.table-responsive > table.table"
  end

  test "index: table uses fixed layout with percentage widths summing to 100%" do
    get credentials_url
    assert_select "table[style*='table-layout: fixed']"
    assert_select "th[style='width: 12%']", text: "Name"
    assert_select "th[style='width: 20%']", text: "Username"
    assert_select "th[style='width: 18%']", text: "Url"
    assert_select "th[style='width: 28%']", text: "Password"
    assert_select "th[style='width: 22%']"
  end


  test "index: username clipboard button precedes username text in DOM" do
    get credentials_url
    assert_select "button[aria-label='Copia username'] i.bi-clipboard"
    assert_match(/Copia username.*#{Regexp.escape(@credential.username)}/m, response.body)
  end

  test "index: URL cell has clipboard button and link opening in new tab" do
    get credentials_url
    assert_select "button[aria-label='Copia url'] i.bi-clipboard"
    assert_select "a[href='#{@credential.url}'][target='_blank'][rel='noopener noreferrer']"
  end

  test "index: password clipboard button precedes reveal button in DOM" do
    get credentials_url
    assert_select "button[aria-label='Copia password'] i.bi-clipboard"
    assert_select "a.btn[aria-label='Mostra'] i.bi-eye"
    assert_match(/Copia password.*Mostra/m, response.body)
  end

  test "index: reveal password link has button styling" do
    get credentials_url
    assert_select "a.btn.btn-sm.btn-outline-secondary[aria-label='Mostra'] i.bi-eye"
  end

  test "index: note popover button shown when note is present" do
    get credentials_url
    assert_select "button[data-bs-toggle='popover'][title='Note'] i.bi-sticky"
    assert_match(/data-bs-content="#{Regexp.escape(@credential.note)}"/, response.body)
  end

  test "index: note popover button not rendered when note is blank" do
    Credential.create!(name: 'No Note', username: 'u', password: 'pw',
                       url: 'https://x.com', note: '', user: @user)
    get credentials_url
    # two renders: mobile card + desktop table, both show the button only for @credential
    assert_select "button[data-bs-toggle='popover']", count: 2
  end

  test "index: note, edit and delete buttons are in the same text-nowrap cell" do
    get credentials_url
    assert_select "td.text-nowrap button[aria-label='Note'] i.bi-sticky"
    assert_select "td.text-nowrap a[aria-label='Modifica'] i.bi-pencil"
    assert_select "td.text-nowrap a[aria-label='Cancella'] i.bi-trash"
  end


  test "index: search button has bi-search icon" do
    get credentials_url
    assert_select "button[type='submit'] i.bi-search"
  end

  test "index: new credential button has bi-plus-circle icon" do
    get credentials_url
    assert_select "a[href='#{new_credential_path}'] i.bi-plus-circle"
  end

  test "show: clipboard buttons present for username and password" do
    get credential_url(@credential)
    assert_select "button[aria-label='Copia username'] i.bi-clipboard"
    assert_select "button[aria-label='Copia password'] i.bi-clipboard"
  end

  test "show: username clipboard button precedes username text in DOM" do
    get credential_url(@credential)
    assert_match(/Copia username.*#{Regexp.escape(@credential.username)}/m, response.body)
  end

  test "show: password clipboard button precedes reveal button in DOM" do
    get credential_url(@credential)
    assert_match(/Copia password.*aria-label="Mostra"/m, response.body)
  end

  test "show: reveal password link has button styling and eye icon" do
    get credential_url(@credential)
    assert_select "a.btn.btn-sm.btn-outline-secondary[aria-label='Mostra'] i.bi-eye"
  end

  test "show: edit and credentials buttons have Bootstrap icons" do
    get credential_url(@credential)
    assert_select "a[href='#{edit_credential_path(@credential)}'] i.bi-pencil"
    assert_select "a[href='#{credentials_path}'] i.bi-key"
  end

  test "reveal_password: eye-slash button precedes password code in DOM" do
    get reveal_password_credential_url(@credential)
    assert_select "a.btn[aria-label='Nascondi'] i.bi-eye-slash"
    assert_match(/Nascondi.*<code>/m, response.body)
  end

  test "reveal_password: mobile variant uses password_m_ frame id" do
    get reveal_password_credential_url(@credential, mobile: 1)
    assert_select "turbo-frame[id='password_m_#{@credential.id}']"
    assert_select "a.btn[aria-label='Nascondi'] i.bi-eye-slash"
  end

  test "hide_password: eye button is present" do
    get hide_password_credential_url(@credential)
    assert_select "a.btn[aria-label='Mostra'] i.bi-eye"
  end

  test "hide_password: mobile variant uses password_m_ frame id" do
    get hide_password_credential_url(@credential, mobile: 1)
    assert_select "turbo-frame[id='password_m_#{@credential.id}']"
    assert_select "a.btn[aria-label='Mostra'] i.bi-eye"
  end

  # ===== Cloudflare email obfuscation protection =====

  test "reveal_password: response is wrapped in email_off comments" do
    get reveal_password_credential_url(@credential)
    assert_match(/<!--email_off-->.*<!--\/email_off-->/m, response.body)
  end

  test "reveal_password: password with @ renders inside email_off region" do
    cred = Credential.create!(name: "AtSign", username: "u", password: "p@ssw0rd",
                              url: "https://x.com", note: "", user: @user)
    get reveal_password_credential_url(cred)
    assert_match(/<!--email_off-->.*p@ssw0rd.*<!--\/email_off-->/m, response.body)
    assert_no_match(/href="mailto:/, response.body)
  end
end
