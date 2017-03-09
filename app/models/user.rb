class User < ActiveRecord::Base
  #validations from form
  validates :class_number, presence: true, numericality: {:greater_than => 0, :less_than => 15}, :allow_blank => true
  validates :time_zone, presence: true, :numericality => true, :allow_blank => true
  validates :paused_time, presence: true, :allow_blank => true

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook]

  has_many :groups

  accepts_nested_attributes_for :groups

  def email_required?
    false
  end

  def email_changed?
    false
  end

  # FACEBOOK LOGIN METHODS
  def self.from_omniauth(auth, conversation_id)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      # setting the user info
      user.first_name = auth.info.first_name
      user.provider = auth.provider
      user.uid = auth.uid
      user.password = Devise.friendly_token[0,20]
      user.email = auth.info.email
      user.conversation_id = conversation_id
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.first_name = data["first_name"] if user.first_name.blank?
        user.password = Devise.friendly_token[0,20]
        user.provider = data["provider"]
        user.uid = data["uid"]
    end
  end
end
end
