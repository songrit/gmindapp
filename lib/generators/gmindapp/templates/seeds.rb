if Identity.count==0
  identity= Identity.create :name => "admin", :email => "admin@test.com", :password => "secret",
    :password_confirmation => "secret"
  User.create :provider => "identity", :uid => identity.id.to_s, :name => identity.name,
    :email => identity.email, :role => "M,A,D"
end
