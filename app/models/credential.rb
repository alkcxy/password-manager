class Credential
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :user, type: String
  field :password, type: PasswordType
  field :url, type: String
  field :note, type: String

  index({ name: 1, user: 1 }, { unique: true })
  index "$**": "text"

  validates :user, uniqueness: { scope: :name, case_sensitive: false }
  validates_presence_of :name
  validates_presence_of :user
  validates_presence_of :password
  validates_presence_of :url

end
