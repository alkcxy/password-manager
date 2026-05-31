require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "valid user is saved" do
    user = User.new(name: 'Alice', email: 'alice@example.com',
                    password: 'password123', password_confirmation: 'password123')
    assert user.save
  end

  test "requires email" do
    user = User.new(name: 'Alice', password: 'password123', password_confirmation: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], "non può essere vuoto"
  end

  test "requires password of at least 8 characters" do
    user = User.new(name: 'Alice', email: 'alice@example.com',
                    password: 'short', password_confirmation: 'short')
    assert_not user.valid?
  end

  test "rejects duplicate email" do
    User.create!(name: 'Alice', email: 'alice@example.com',
                 password: 'password123', password_confirmation: 'password123')
    dup = User.new(name: 'Bob', email: 'alice@example.com',
                   password: 'password123', password_confirmation: 'password123')
    assert_not dup.valid?
  end

  test "authenticate returns user on correct password" do
    user = User.create!(name: 'Alice', email: 'alice@example.com',
                        password: 'password123', password_confirmation: 'password123')
    assert user.authenticate('password123')
  end

  test "authenticate returns false on wrong password" do
    user = User.create!(name: 'Alice', email: 'alice@example.com',
                        password: 'password123', password_confirmation: 'password123')
    assert_equal false, user.authenticate('wrongpassword')
  end
end
