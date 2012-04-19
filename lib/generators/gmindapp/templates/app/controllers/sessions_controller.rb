# encoding: utf-8
class SessionsController < ApplicationController
  def new
    @title= 'เข้าใช้ระบบ'
  end

  def create
    user = User.from_omniauth(env["omniauth.auth"])
    session[:user_id] = user.id
    render :text => "<script>window.location.replace('/gmindapp/pending')</script>", :layout=> true
  end

  def destroy
    session[:user_id] = nil
    render :text => "<script>window.location.assign('/gmindapp/help')</script>", :layout => true 
  end

  def failure
    redirect_to root_url, :alert=> "Authentication failed, please try again."
  end
end
