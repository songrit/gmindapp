class Gmindapp::Service
  include Mongoid::Document
  field :module, :type => String
  field :code, :type => String
  field :name, :type => String
  field :xml, :type => String
  field :role, :type => String
  field :rule, :type => String
  field :seq, :type => Integer
  field :listed, :type => Boolean
  field :secured, :type => Boolean

  belongs_to :module, :class_name => "Gmindapp::Module"
end
