# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :login?, :get_option_xml, :listed, :secured?, :own_xmain?

  # todo: move login? to gem helper
  def login?
    session[:user_id] != nil
  end
  def own_xmain?
    if $xvars
      return current_user.id==$xvars[:user_id]
    else
      return true
    end
  end
  def get_option_xml(opt, xml)
    if xml
      url=''
      xml.each_element('node') do |n|
        text= n.attributes['TEXT']
        url= text if text =~/^#{opt}/
      end
      return nil if url.blank?
      c, h= url.split(':', 2)
      opt= h ? h.strip : true
    else
      return nil
    end
  end
  def listed(node)
    icons=[]
    node.each_element("icon") do |nn|
      icons << nn.attributes["BUILTIN"]
    end
    return !icons.include?("closed")
  end
  def secured?(node)
    icons=[]
    node.each_element("icon") do |nn|
      icons << nn.attributes["BUILTIN"]
    end
    return icons.include?("password")
  end
  def freemind2action(s)
    case s.downcase
    #when 'bookmark' # Excellent
    #  'call'
    when 'bookmark' # Excellent
      'do'
    when 'attach' # Look here
      'form'
    when 'edit' # Refine
      'pdf'
    when 'wizard' # Magic
      'ws'
    when 'help' # Question
      'if'
    when 'forward' # Forward
      'redirect'
    when 'kaddressbook' #Phone
      'invoke' # invoke new service along the way
    when 'pencil'
      'output'
    when 'mail'
      'mail'
    end
  end
  def affirm(s)
    return s =~ /[y|yes|t|true]/i ? true : false
  end
  def negate(s)
    return s =~ /[n|no|f|false]/i ? true : false
  end
end
