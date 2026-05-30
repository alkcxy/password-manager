require 'test_helper'

class CredentialTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: 'Alice', email: 'alice@example.com',
                         password: 'password123', password_confirmation: 'password123')
  end

  test "valid credential is saved" do
    cred = Credential.new(name: 'GitHub', username: 'alice',
                          password: 'secret', url: 'https://github.com',
                          note: '', user: @user)
    assert cred.save
  end

  test "requires name" do
    cred = Credential.new(username: 'alice', password: 'secret',
                          url: 'https://github.com', user: @user)
    assert_not cred.valid?
    assert_includes cred.errors[:name], "can't be blank"
  end

  test "requires user" do
    cred = Credential.new(name: 'GitHub', username: 'alice',
                          password: 'secret', url: 'https://github.com')
    assert_not cred.valid?
  end

  test "requires username" do
    cred = Credential.new(name: 'GitHub', password: 'secret',
                          url: 'https://github.com', user: @user)
    assert_not cred.valid?
    assert_includes cred.errors[:username], "can't be blank"
  end

  test "password is encrypted at rest" do
    cred = Credential.create!(name: 'GitHub', username: 'alice',
                               password: 'mysecret', url: 'https://github.com',
                               note: '', user: @user)
    raw = Mongoid.default_client[:credentials].find(_id: cred.id).first
    assert_not_equal 'mysecret', raw[:password]
  end

  test "password is decrypted when read" do
    cred = Credential.create!(name: 'GitHub', username: 'alice',
                               password: 'mysecret', url: 'https://github.com',
                               note: '', user: @user)
    reloaded = Credential.find(cred.id)
    assert_equal 'mysecret', reloaded.password
  end
end
