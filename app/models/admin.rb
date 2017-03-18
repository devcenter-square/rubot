class Admin < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
    :rememberable, :trackable, :validatable,
    :omniauthable, :omniauth_providers => [:google_oauth2]

    #:registerable removed to disable signup
    #:recoverable removed to disable password recovery

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |admin|
      # todo: prolly wanna limit this to the devcenter admins?
      admin.provider = auth.provider
      admin.uid = auth.uid
      admin.email = auth.info.email
      admin.password = Devise.friendly_token[0,20]
    end
  end
end
