require "application_system_test_case"

class ExtensionBannerTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Banner User", email: "banner@example.com",
                         password: "password123", password_confirmation: "password123")
    visit login_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_on "Login"
  end

  teardown do
    page.execute_script("localStorage.removeItem('pm_ext_installed')") rescue nil
  end

  test "banner visibile al primo accesso" do
    visit credentials_url
    assert_selector "[data-controller='extension-banner']"
  end

  test "banner assente se extension gia' attiva (localStorage da visita precedente)" do
    page.execute_script("localStorage.setItem('pm_ext_installed', '1')")
    visit credentials_url
    assert_no_selector "[data-controller='extension-banner']"
  end

  test "banner sparisce quando il content script si attiva sulla pagina corrente" do
    visit credentials_url
    assert_selector "[data-controller='extension-banner']"
    page.execute_script("window.dispatchEvent(new CustomEvent('pm-ext-installed'))")
    assert_no_selector "[data-controller='extension-banner']", wait: 1
  end

  test "banner si chiude al click su Chiudi" do
    visit credentials_url
    assert_selector "[data-controller='extension-banner']"
    find("[data-action='extension-banner#dismiss']").click
    assert_no_selector "[data-controller='extension-banner']", wait: 2
  end

  test "banner non riappare dopo dismiss nella stessa sessione" do
    visit credentials_url
    find("[data-action='extension-banner#dismiss']").click
    assert_no_selector "[data-controller='extension-banner']", wait: 2
    visit credentials_url
    assert_no_selector "[data-controller='extension-banner']"
  end
end
