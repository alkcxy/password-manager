class User
  include Mongoid::Document
  include ActiveModel::SecurePassword
  include Mongoid::Timestamps

  field :name, type: String
  field :email, type: String
  field :password_digest, type: String

  has_secure_password
end
