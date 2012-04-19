# -*- encoding : utf-8 -*-
class GmindappController < ApplicationController
  def index
    if login?
      @xmains= Gmindapp::Xmain.all.also_in(:status=>['R','I']).order("created_at")
    end
    render :layout => false 
  end
  def end_action
    redirect_to :action=> "pending"
  end
  def about
    render :layout => false 
  end
  def store_asset
    if params[:content]
      doc = GmaDoc.create! :name=> 'asset',
        :filename=> (params[:file_name]||''),
        :content_type => (params[:content_type] || 'application/zip'),
        :data_text=> '',
        :display=>true 
      path = (IMAGE_LOCATION || "tmp")
      File.open("#{path}/f#{doc.id}","wb") { |f|
        f.puts(params[:content])
      }
      render :xml=>"<elocal><doc id='#{doc.id}' /><success /></elocal>"
    else
      render :xml=>"<elocal><fail /></elocal>"
    end
  end
  def status
    @xmain= GmaXmain.find params[:id]
    @title= "Task number #{params[:id]} #{@xmain.name}"
    @backbtn= true
    @xvars= @xmain.xvars
    # flash.now[:notice]= "รายการ #{@xmain.id} ได้ถูกยกเลิกแล้ว" if @xmain.status=='X'
    gma_notice "Task #{@xmain.id} is cancelled" if @xmain.status=='X'
    # flash.now[:notice]= "transaction #{@xmain.id} was cancelled" if @xmain.status=='X'
  rescue
    # flash[:notice]= "ขออภัย ไม่สามารถค้นหางานเลขที่ <b> #{params[:id]} </b>"
    gma_notice "Could not find task number <b> #{params[:id]} </b>"
    redirect_to_root
  end
  def help
#    render :text => "help"
  end
  def pending
    @xmains= GmaXmain.all :conditions=>"status='R' or status='I' ", :order=>"created_at", :include=>:gma_runseqs
  end
  def search
    @q = params[:q] || params[:gma_search][:q] || ""
    @title = "ผลการค้นหา #{@q}"
    @backbtn= true
    @cache= true
    if @q.blank?
      redirect_to "/"
    else
      s= GmaSearch.create :q=>@q, :ip=> request.env["REMOTE_ADDR"]
      do_search
    end
  end
  def do_search
    if current_user.secured?
      @docs = GmaDoc.search_secured(@q.downcase, params[:page], PER_PAGE)
    else
      @docs = GmaDoc.search(@q.downcase, params[:page], PER_PAGE)
    end
    @xmains = GmaXmain.find(@docs.map(&:gma_xmain_id)).sort { |a,b| b.id<=>a.id }
    # @xmains = GmaXmain.find @docs.map(&:created_at).sort { |a,b| b<=>a }
  end
  def err404
    gma_log 'ERROR', 'main/err404'
    flash[:notice] = "We're sorry, but something went wrong. We've been notified about this issue and we'll take a look at it shortly."
    gma_notice "We're sorry, but something went wrong. We've been notified about this issue and we'll take a look at it shortly."
    # gma_notice "ขออภัย เกิดข้อผิดพลาดรหัส 404 ขึ้นในระบบ กรุณาติดต่อผู้ดูแลระบบ"
    redirect_to '/'
  end
  def err500
    gma_log 'ERROR', 'main/err500'
    flash[:notice] = "We're sorry, but something went wrong. We've been notified about this issue and we'll take a look at it shortly."
    gma_notice "We're sorry, but something went wrong. We've been notified about this issue and we'll take a look at it shortly."
    # gma_notice "ขออภัย เกิดข้อผิดพลาดรหัส 500 ขึ้นในระบบ กรุณาติดต่อผู้ดูแลระบบ"
    redirect_to '/'
  end

  # ajax call to update modules menu and sidebar
  def modules
    @modules= GmaModule.all :order=>"seq"
    render :layout => false
  end
  def sidebar
    @gma_module= GmaModule.find_by_name params[:module]
    # @waypoint= Waypoint.find session[:waypoint_id]
    render :layout => false
  end
end
