# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery

  def authorize_init? # use when initialize new transaction
    xml= @service.xml
    step1 = REXML::Document.new(xml).root.elements['node']
    role= get_option_xml("role", step1) || ""
#    rule= get_option_xml("rule", step1) || true
    return true if role==""
    user= get_user
    unless user
      return role.blank?
    else
      return false unless user.role
      return user.role.upcase.split(',').include?(role.upcase)
    end
  end
  def gma_log(message)
    Gmindapp::Notice.create :message => message, :unread=> true
  end
end
