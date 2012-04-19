# -*- encoding : utf-8 -*-
class Gmindapp::Runseq
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :gma_user
  belongs_to :gma_xmain
  belongs_to :location

  named_scope "form_action", :conditions=>['action=? OR action=? OR action=?','form','output','pdf']

  field :action, :type => String
  field :status, :type => String
  field :code, :type => String
  field :name, :type => String
  field :role, :type => String
  field :rule, :type => String
  field :rstep, :type => Integer
  field :form_step, :type => Integer
  field :start, :type => DateTime
  field :stop, :type => DateTime
  field :end, :type => Boolean
  field :xml, :type => String
  field :ip, :type => String
end
