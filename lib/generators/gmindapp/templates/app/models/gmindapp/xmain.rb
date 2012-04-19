# -*- encoding : utf-8 -*-
class Gmindapp::Xmain
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :gma_user
  belongs_to :gma_service
  has_many :gma_runseqs, :order=>"rstep"
  has_many :comments, :order=>"created_at"
  has_many :gma_docs, :order=>"created_at"

  field :status, :type => String
  field :xvars, :type => Hash
  field :start, :type => DateTime
  field :stop, :type => DateTime
  field :current_runseq, :type => Integer
  field :name, :type => String
  field :ip, :type => String

  # serialize :xvars

  # number of xmains on the specified date
  def self.number(d)
    all(:conditions=>['DATE(created_at) =?', d.to_date]).count
  end
  def self.search(q, page, per_page=10)
    paginate :per_page=>per_page, :page => page, :conditions =>
      ["LOWER(xvars) LIKE ?", "%#{q}%" ],
      :order=>'created_at DESC'
  end
end
