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

  test "banner visibile al primo accesso" do
    visit credentials_url
    assert_selector "[data-controller='extension-banner']"
  end

  test "banner assente se extension installata" do
    visit credentials_url
    # Simula install_marker.js: setta l'attributo su <html>, poi Turbo.visit
    # re-renderizza il body con Stimulus che riconnette trovando l'attributo già presente
    page.execute_script("document.documentElement.setAttribute('data-pm-ext-installed', '')")
    page.execute_script("Turbo.visit(window.location.href, { action: 'replace' })")
    assert_no_selector "[data-controller='extension-banner']", wait: 3
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
