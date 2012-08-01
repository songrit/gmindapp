class User
  include Mongoid::Document
  field :provider, :type => String
  field :uid, :type => String
  field :name, :type => String
  field :email, :type => String
  field :role, :type => String
  
  def self.from_omniauth(auth)
    where(:provider=> auth["provider"], :uid=> auth["uid"]).first || create_with_omniauth(auth)
  end
  
  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.email = auth.info.email
      user.role = "M"
    end
  end

  def secured?
    role.upcase.split(',').include?(SECURED_ROLE)
  end
end
