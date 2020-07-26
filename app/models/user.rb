class User
  include Mongoid::Document
  include ActiveModel::SecurePassword
  include Mongoid::Timestamps

  field :name, type: String
  field :email, type: String
  field :password_digest, type: String

  has_secure_password

  index({ email: 1 }, { unique: true })
  validates_length_of :password, minimum: 8
  validates_presence_of :email
  validates_uniqueness_of :email
end
