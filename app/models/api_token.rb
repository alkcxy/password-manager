class ApiToken
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token,      type: String
  field :expires_at, type: DateTime

  belongs_to :user

  index({ token: 1 }, { unique: true })

  validates_presence_of :token, :expires_at, :user
  validates_uniqueness_of :token

  TTL_DAYS = (ENV["API_TOKEN_TTL_DAYS"] || 30).to_i

  def self.generate_for(user)
    create!(
      token:      SecureRandom.hex(32),
      user:       user,
      expires_at: TTL_DAYS.days.from_now
    )
  end

  def expired?
    expires_at < Time.current
  end

  scope :valid, -> { where(:expires_at.gt => Time.current) }
end
