class Gmindapp::Notice
  include Mongoid::Document
  include Mongoid::Timestamps
  field :message, :type => String
  field :unread, :type => Boolean
  belongs_to :user
  
  # scope :new, :where=>{:unread=>true}
  scope :recent, where(unread: true)
end
