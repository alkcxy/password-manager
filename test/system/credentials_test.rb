require "application_system_test_case"

class CredentialsTest < ApplicationSystemTestCase
  setup do
    @credential = credentials(:one)
  end

  test "visiting the index" do
    visit credentials_url
    assert_selector "h1", text: "Credentials"
  end

  test "creating a Credential" do
    visit credentials_url
    click_on "New Credential"

    fill_in "Name", with: @credential.name
    fill_in "Note", with: @credential.note
    fill_in "Password", with: @credential.password
    fill_in "Url", with: @credential.url
    fill_in "User", with: @credential.user
    click_on "Create Credential"

    assert_text "Credential was successfully created"
    click_on "Back"
  end

  test "updating a Credential" do
    visit credentials_url
    click_on "Edit", match: :first

    fill_in "Name", with: @credential.name
    fill_in "Note", with: @credential.note
    fill_in "Password", with: @credential.password
    fill_in "Url", with: @credential.url
    fill_in "User", with: @credential.user
    click_on "Update Credential"

    assert_text "Credential was successfully updated"
    click_on "Back"
  end

  test "destroying a Credential" do
    visit credentials_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Credential was successfully destroyed"
  end
end
