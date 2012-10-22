# -*- encoding : utf-8 -*-
class GmindappController < ApplicationController
  def pending
    # @xmains= []
    # @xmains= Gmindapp::Xmain.all :conditions=>"status='R' or status='I' ", :order=>"created_at", :include=>:runseqs
    @xmains= Gmindapp::Xmain.where(status:'R').union.where(status:'I').asc(:created_at)
  end
  def index
    if login?
      @xmains= Gmindapp::Xmain.where(status:'R').union.where(status:'I').asc(:created_at)
      # @xmains= Gmindapp::Xmain.all.also_in(:status=>['R','I']).order("created_at")
    end
    render :layout => false 
  end
  def init
    @service= Gmindapp::Service.where(:module_code=> params[:module], :code=> params[:service]).first
    if @service && authorize_init?
      xmain = create_xmain(@service)
      result = create_runseq(xmain)
      unless result
        message = "cannot find action for xmain #{xmain.id}"
        gma_log("ERROR", message)
        flash[:notice]= message
        # gma_notice message
        redirect_to "pending" and return
      end
      xmain.update_attribute(:xvars, @xvars)
      xmain.runseqs.last.update_attribute(:end,true)
      redirect_to :action=>'run', :id=>xmain.id
    else
      flash[:notice]= "ขออภัย ไม่สามารถทำงานได้"
      gma_notice "ขออภัย ไม่สามารถทำงานได้"
      gma_log("SECURITY", "unauthorize access: #{params.inspect}")
      redirect_to_root
    end
  end
  def run
    init_vars(params[:id])
    if authorize?
      # session[:full_layout]= false
      redirect_to(:action=>"run_#{@runseq.action}", :id=>@xmain.id)
    else
      redirect_to_root
    end
  end
  def run_form
    init_vars(params[:id])
    if authorize?
      if ['F', 'X'].include? @xmain.status
        redirect_to_root
      else
        @title= "รหัสดำเนินการ #{@xmain.xid}: #{@xmain.name} / #{@runseq.name}"
        service= @xmain.service
        if service
          f= "app/views/#{service.module.code}/#{service.code}/#{@runseq.code}.html.erb"
          @f_help= "app/views/#{service.module.code}/#{service.code}/#{@runseq.code}.redcloth"
          @ui= File.read(f)
        else
          flash[:notice]= "ไม่สามารถค้นหาบริการที่ต้องการได้"
          gma_notice "ไม่สามารถค้นหาบริการที่ต้องการได้"
          redirect_to_root
        end
      end
    else
      redirect_to_root
    end
  end
  def run_do
    init_vars(params[:id])
    @runseq.start ||= Time.now
    @runseq.status= 'R' # running
    $runseq_id= @runseq.id; $user_id= current_user.id
    set_global
    controller = Kernel.const_get(@xvars['custom_controller']).new
    result = controller.send(@runseq.code)
    init_vars_by_runseq($runseq_id)
    @xvars = $xvars
    @xvars[@runseq.code.to_sym]= result.to_s
    @xvars['current_step']= @runseq.rstep
    @runseq.status= 'F' #finish
    @runseq.stop= Time.now
    @runseq.save
    end_action
  rescue => e
    @xmain.status='E'
    @xvars['error']= e.to_s
    @xmain.xvars= $xvars
    @xmain.save
    @runseq.status= 'F' #finish
    @runseq.stop= Time.now
    @runseq.save
    gma_log "ขออภัย เกิดข้อผิดพลาดในรหัสการดำเนินงาน #{@xmain.id}"
    # flash[:notice]= "Sorry, there was some problem processing your request."
#    flash[:notice]= "ERROR: Job Abort xmain #{@xmain.id} runseq #{@runseq.id}<br/>#{xml_text e}<hr/>"
    # gma_log("ERROR", "Job Abort xmain #{@xmain.id} runseq #{@runseq.id}<br/>#{xml_text e}<hr/>")
#    end_action(nil)
#    end_action
    redirect_to_root
  end
  def run_output
    init_vars(params[:id])
    service= @xmain.service
    disp= get_option("display")
    display = (disp && !affirm(disp)) ? false : true
    if service
      f= "app/views/#{service.module.code}/#{service.code}/#{@runseq.code}.html.erb"
      @ui= File.read(f)
      if Gmindapp::Doc.where(:runseq_id=>@runseq.id).exists?
        @doc= Gmindapp::Doc.where(:runseq_id=>@runseq.id).first
        @doc.update_attributes :data_text=> render_to_string(:inline=>@ui, :layout=>"utf8"),
          :xmain=>@xmain, :runseq=>@runseq, :user=>current_user,
          :ip=> get_ip, :service=>service, :display=>display,
          :secured => @xmain.service.secured
      else
        @doc= Gmindapp::Doc.create :name=> @runseq.name,
          :content_type=>"output", :data_text=> render_to_string(:inline=>@ui, :layout=>"utf8"),
          :xmain=>@xmain, :runseq=>@runseq, :user=>current_user,
          :ip=> get_ip, :service=>service, :display=>display,
          :secured => @xmain.service.secured
      end
      @message = defined?(MSG_NEXT) ? MSG_NEXT : "Next &gt;"
      @message = "สิ้นสุดการทำงาน" if @runseq.end
      eval "@xvars[@runseq.code] = url_for(:controller=>'gmindapp', :action=>'document', :id=>@doc.id)"
    else
      flash[:notice]= "ไม่สามารถค้นหาบริการที่ต้องการได้"
      gma_notice "ไม่สามารถค้นหาบริการที่ต้องการได้"
      redirect_to_root
    end
    #display= get_option("display")
    unless display
      end_action
    end
  end
  def end_output
    init_vars(params[:xmain_id])
    end_action
  end
  def end_form
    init_vars(params[:xmain_id])
    eval "@xvars[@runseq.code] = {} unless @xvars[@runseq.code]"
    params.each { |k,v|
      if params[k].respond_to? :original_filename
        get_image(k, params[k])
      elsif params[k].is_a?(Hash)
        eval "@xvars[@runseq.code][k] = v"
        params[k].each { |k1,v1|
          next unless v1.respond_to?(:original_filename)
          get_image1(k, k1, params[k][k1])
        }
      else
        eval "@xvars[@runseq.code][k] = v"
      end
    }
    end_action
  end
  # process images from first level
  def get_image(key, params)
    # use mongo to store image
#    upload = Upload.create :content=> params.read
    doc = Gmindapp::Doc.create(
      :name=> key.to_s,
      :xmain=> @xmain.id,
      :runseq=> @runseq.id,
      :filename=> params.original_filename,
      :content_type => params.content_type || 'application/zip',
 #     :data_text=> upload.id.to_s,
      :data_text=> '',
      :display=>true,
      :secured => @xmain.service.secured )
    path = defined?(IMAGE_LOCATION) ? IMAGE_LOCATION : "tmp"
    File.open("#{path}/f#{doc.id}","wb") { |f|
      f.puts(params.read)
    }
    eval "@xvars[@runseq.code][key] = '#{url_for(:action=>'document', :id=>doc.id, :only_path => true )}' "
    # eval "@xvars[:#{@runseq.code}][:#{key}_doc_id] = #{doc.id} "
  end
  # process images from second level, e.g,, fields_for
  def get_image1(key, key1, params)
    # use mongo to store image
#    upload = Upload.create :content=> params.read
    doc = GmaDoc.create(
      :name=> "#{key}_#{key1}",
      :xmain=> @xmain.id,
      :runseq=> @runseq.id,
      :filename=> params.original_filename,
      :content_type => params.content_type || 'application/zip',
#      :data_text=> upload.id.to_s,
      :data_text=> '',
      :display=>true, :secured => @xmain.service.secured )
    path = defined?(IMAGE_LOCATION) ? IMAGE_LOCATION : "tmp"
    File.open("#{path}/f#{doc.id}","wb") { |f|
       f.puts(params.read)
   }

    eval "@xvars[@runseq.code][key][key1] = '#{url_for(:action=>'document', :id=>doc.id, :only_path => true)}' "
    # eval "@xvars[:#{@runseq.code}][:#{doc.name}_doc_id] = #{doc.id} "
  end
  def doc_print
    render :file=>'public/doc.html', :layout=>'layouts/print'
  end
  def doc
    require 'rdoc'
    @app= get_app
    @name = 'ระบบงานสินเชื่อติดตั้งแก๊ซใช้ในรถยนต์'
    @intro = File.read('README.md')
    @print= "<div align='right'><img src='/assets/printer.png'/> <a href='/gmindapp/doc_print' target='_blank'/>พิมพ์</a></div>"
    doc= render_to_string 'doc.md', :layout => false
    html= Maruku.new(doc).to_html
    File.open('public/doc.html','w') {|f| f.puts html }
    respond_to do |format|
      format.html { 
        render :text=> @print+html, :layout => 'layouts/_page'
        # render :text=> Maruku.new(doc).to_html, :layout => false
      # format.html { 
      #   h = RDoc::Markup::ToHtml.new
      #   render :text=> h.convert(doc), :layout => 'layouts/_page' 
      }
      format.pdf  { 
        latex= Maruku.new(doc).to_latex
        File.open('tmp/doc.md','w') {|f| f.puts doc}
        File.open('tmp/doc.tex','w') {|f| f.puts latex}
        # system('pdflatex tmp/doc.tex ')
        # send_file( 'tmp/doc.pdf', :type => ‘application/pdf’,
          # :disposition => ‘inline’, :filename => 'doc.pdf')
        render :text=>'done'
      }
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
  
  private
  def create_xmain(service)
    c = name2camel(service.module.code)
    custom_controller= "#{c}Controller"
    Gmindapp::Xmain.create :service=>service,
      :start=>Time.now,
      :name=>service.name,
      :ip=> get_ip,
      :status=>'I', # init
      :user=>current_user,
      :xvars=> {
        :service_id=>service.id, :p=>params,
        :id=>params[:id],
        :user_id=>current_user.id, :custom_controller=>custom_controller,
        :host=>request.host,
        :referer=>request.env['HTTP_REFERER'] }
  end
  def create_runseq(xmain)
    @xvars= xmain.xvars
    default_role= get_default_role
    xml= xmain.service.xml
    root = REXML::Document.new(xml).root
    i= 0; j= 0 # i= step, j= form_step
    root.elements.each('node') do |activity|
      text= activity.attributes['TEXT']
      next if gma_comment?(text)
      next if text =~/^rule:\s*/
      action= freemind2action(activity.elements['icon'].attributes['BUILTIN']) if activity.elements['icon']
      return false unless action
      i= i + 1
      output_display= false
      if action=='output'
        display= get_option_xml("display", activity)
        if display && !affirm(display)
          output_display= false
        else
          output_display= true
        end
      end
      j= j + 1 if (action=='form' || output_display)
      @xvars['referer'] = activity.attributes['TEXT'] if action=='redirect'
      if action!= 'if'
        scode, name= text.split(':', 2)
        name ||= scode; name.strip!
        code= name2code(scode)
      else
        code= text
        name= text
      end
      role= get_option_xml("role", activity) || default_role
      rule= get_option_xml("rule", activity) || "true"
      runseq= Gmindapp::Runseq.create :xmain=>xmain.id,
        :name=> name, :action=> action,
        :code=> code, :role=>role.upcase, :rule=> rule,
        :rstep=> i, :form_step=> j, :status=>'I',
        :xml=>activity.to_s
      xmain.current_runseq= runseq.id if i==1
    end
    @xvars['total_steps']= i
    @xvars['total_form_steps']= j
  end
  def init_vars(xmain)
    @xmain= Gmindapp::Xmain.find xmain
    @xvars= @xmain.xvars
    @runseq= @xmain.runseqs.find @xmain.current_runseq
#    authorize?
    @xvars['current_step']= @runseq.rstep
    @xvars['referrer']= request.referrer
    session[:xmain_id]= @xmain.id
    session[:runseq_id]= @runseq.id
    unless params[:action]=='run_call'
      @runseq.start ||= Time.now
      @runseq.status= 'R' # running
      @runseq.save
    end
    $xmain= @xmain; $xvars= @xvars
    $runseq_id= @runseq.id; $user_id= current_user.id
  end
  def init_vars_by_runseq(runseq_id)
    @runseq= Gmindapp::Runseq.find runseq_id
    @xmain= @runseq.xmain
    @xvars= @xmain.xvars
    #@xvars[:current_step]= @runseq.rstep
    @runseq.start ||= Time.now
    @runseq.status= 'R' # running
    @runseq.save
  end
  # def end_action(next_runseq = nil)
  #   #    @runseq.status='F' unless @runseq_not_f
  #   @xmain.xvars= @xvars
  #   @xmain.status= 'R' # running
  #   @xmain.save
  #   @runseq.status='F'
  #   @runseq.gma_user_id= session[:user_id]
  #   @runseq.stop= Time.now
  #   @runseq.save
  #   next_runseq= @xmain.gma_runseqs.find_by_rstep @runseq.rstep+1 unless next_runseq
  #   if @end_job || !next_runseq # job finish
  #     @xmain.xvars= @xvars
  #     @xmain.status= 'F' unless @xmain.status== 'E' # finish
  #     @xmain.stop= Time.now
  #     @xmain.save
  #     if @xvars['p']['return']
  #       redirect_to @xvars['p']['return'] and return
  #     else
  #       redirect_to_root and return
  #     end
  #   else
  #     @xmain.update_attribute :current_runseq, next_runseq.id
  #     redirect_to :action=>'run', :id=>@xmain.id and return
  #   end
  # end
  def end_action(next_runseq = nil)
    #    @runseq.status='F' unless @runseq_not_f
    @xmain.xvars= @xvars
    @xmain.status= 'R' # running
    @xmain.save
    @runseq.status='F'
    @runseq.user= current_user
    @runseq.stop= Time.now
    @runseq.save
    next_runseq= @xmain.runseqs.where(:rstep=> @runseq.rstep+1).first unless next_runseq
    if @end_job || !next_runseq # job finish
      @xmain.xvars= @xvars
      @xmain.status= 'F' unless @xmain.status== 'E' # finish
      @xmain.stop= Time.now
      @xmain.save
      if @xvars['p']['return']
        redirect_to @xvars['p']['return'] and return
      else
        redirect_to :action=>'pending' and return
      end
    else
      @xmain.update_attribute :current_runseq, next_runseq.id
      redirect_to :action=>'run', :id=>@xmain.id and return
    end
  end
  # def about
  #   render :layout => false 
  # end
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
  def do_search
    if current_user.secured?
      @docs = GmaDoc.search_secured(@q.downcase, params[:page], PER_PAGE)
    else
      @docs = GmaDoc.search(@q.downcase, params[:page], PER_PAGE)
    end
    @xmains = GmaXmain.find(@docs.map(&:gma_xmain_id)).sort { |a,b| b.id<=>a.id }
    # @xmains = GmaXmain.find @docs.map(&:created_at).sort { |a,b| b<=>a }
  end
end
