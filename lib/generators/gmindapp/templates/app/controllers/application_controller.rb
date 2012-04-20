# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :login?
  
  def login?
    session[:user_id] != nil
  end
end
