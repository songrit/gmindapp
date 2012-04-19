# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include Gmindapp
  
  def login?
    true
  end
  
end
