ENV['RAILS_ENV'] ||= 'test'
require 'base64'
ENV['SECRET_PM'] ||= Base64.strict_encode64('a' * 32)

require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  setup do
    Mongoid.purge!
  end
end
