class Gmindapp::Role
  include Mongoid::Document
  include Mongoid::Timestamps
  field :code, :type => String
  field :name, :type => String
  belongs_to :user
end
