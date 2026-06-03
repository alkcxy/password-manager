class Credential
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :username, type: String
  field :password, type: PasswordType
  field :url, type: String
  field :note, type: String

  belongs_to :user

  index({ name: 1, user_id: 1 }, { unique: true })
  index({ user_id: 1, name: "text", url: "text" })

  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }
  validates_presence_of :name
  validates_presence_of :user
  validates_presence_of :username
  validates_presence_of :password
  validates_presence_of :url

end
