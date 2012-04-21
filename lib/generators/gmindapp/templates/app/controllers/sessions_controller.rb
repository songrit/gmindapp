# encoding: utf-8
class SessionsController < ApplicationController
  def new
    @title= 'เข้าใช้ระบบ'
  end

  # to refresh the page, must know BEFOREHAND that the action needs refresh
  # then use attribute 'data-ajax'=>'false'
  # see app/views/sessions/new.html.erb for sample
  def create
    user = User.from_omniauth(env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to '/gmindapp/pending'
  end

  def destroy
    session[:user_id] = nil
    redirect_to '/gmindapp/help'
  end

  def failure
    redirect_to root_url, :alert=> "Authentication failed, please try again."
  end
end
