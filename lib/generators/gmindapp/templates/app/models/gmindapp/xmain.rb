# -*- encoding : utf-8 -*-
class Gmindapp::Xmain
  include Mongoid::Document
  # gmindapp begin
  include Mongoid::Timestamps
  belongs_to :service, :class_name => "Gmindapp::Service"
  field :start, :type => DateTime
  field :stop, :type => DateTime
  field :name, :type => String
  field :ip, :type => String
  field :status, :type => String
  belongs_to :user
  field :xvars, :type => Hash
  field :current_runseq, :type => String
  # gmindapp end

  has_many :runseqs, :class_name => "Gmindapp::Runseq"

  # has_many :gma_runseqs, :order=>"rstep"
  # has_many :comments, :order=>"created_at"
  # has_many :gma_docs, :order=>"created_at"

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
