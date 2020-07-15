class Credential
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :user, type: String
  field :password, type: PasswordType
  field :url, type: String
  field :note, type: String
end
