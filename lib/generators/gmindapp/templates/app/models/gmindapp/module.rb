class Gmindapp::Module
  include Mongoid::Document
  field :code, :type => String
  field :name, :type => String
  field :role, :type => String
  field :seq, :type => Integer
  
  has_many :services, :class_name => "Gmindapp::Service"
end
