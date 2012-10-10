module Gmindapp
  module Helpers

    # methods from application_controller

    def gma_comment?(s)
      s[0]==35
    end
    def get_ip
      request.env['HTTP_X_FORWARDED_FOR'] || request.env['REMOTE_ADDR']
    end
    def get_default_role
      default_role= Gmindapp::Role.where(:code =>'default').first
      return default_role ? default_role.name.to_s : ''
    end
    def name2code(s)
      # rather not ignore # symbol cause it could be comment
      code, name = s.split(':')
      code.downcase.strip.gsub(' ','_').gsub(/[^#_\/a-zA-Z0-9]/,'')
    end
    def name2camel(s)
      s.gsub(' ','_').camelcase
    end
    def true_action?(s)
      %w(call ws redirect invoke email).include? s
    end
    def set_global
      $xmain= @xmain ; $runseq = @runseq ; $user = current_user ; $xvars= @xmain.xvars
    end
    def authorize? # use in pending tasks
      @runseq= @xmain.runseqs.find @xmain.current_runseq
      return false unless @runseq
      @user = current_user
      set_global
      return false unless eval(@runseq.rule) if @runseq.rule
      return true if true_action?(@runseq.action)
      # return false if check_wait
      return true if @runseq.role.blank?
      if @runseq.role
        return false unless @user.role
        return @user.role.upcase.split(',').include?(@runseq.role.upcase)
      end
    end
    def authorize_init? # use when initialize new transaction
      xml= @service.xml
      step1 = REXML::Document.new(xml).root.elements['node']
      role= get_option_xml("role", step1) || ""
  #    rule= get_option_xml("rule", step1) || true
      return true if role==""
      user= current_user
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

    # methods from application_helper
    def ajax?(s)
      return s.match('file_field') ? false : true
    end
    def step(s, total) # square text
      s = (s==0)? 1: s.to_i
      total = total.to_i
      out ="<div class='step'>"
      (s-1).times {|ss| out += "<span class='steps_done'>#{(ss+1)}</span>" }
      out += %Q@<span class='step_now' >@
      out += s.to_s
      out += "</span>"
      out += %Q@@
      for i in s+1..total
        out += "<span class='steps_more'>#{i}</span>"
      end
      out += "</div>"
    end

    # old methods, don't know where they came from
    def current_user
      if session[:user_id]
        return @user ||= User.find(session[:user_id])
      else
        return nil
      end
    end
    def ui_action?(s)
      %w(form output mail pdf).include? s
    end
    def handle_gma_notice
      if Gmindapp::Notice.recent.count>0
        notice= Gmindapp::Notice.recent.last
        notice.update_attribute :unread, false
        "<script>notice('#{notice.message}');</script>"
      else
        ""
      end
    end
    def process_services
      # todo: persist mm_md5
      xml= @app||get_app
      if defined? session
        md5= Digest::MD5.hexdigest(xml.to_s)
        if session[:mm_md5]
          return if session[:mm_md5]==md5
        else
          session[:mm_md5]= md5
        end
      end
      protected_services = []
      protected_modules = []
      mseq= 0
      @services= xml.elements["//node[@TEXT='services']"] || REXML::Document.new
      @services.each_element('node') do |m|
        ss= m.attributes["TEXT"]
        code, name= ss.split(':', 2)
        next if code.blank?
        next if code.comment?
        module_code= code.to_code
        # create or update to GmaModule
        gma_module= Gmindapp::Module.find_or_create_by :code=>module_code
        gma_module.update_attributes :uid=>gma_module.id.to_s
        protected_modules << gma_module.uid
        name = module_code if name.blank?
        gma_module.update_attributes :name=> name.strip, :seq=> mseq
        mseq += 1
        seq= 0
        m.each_element('node') do |s|
          service_name= s.attributes["TEXT"].to_s
          scode, sname= service_name.split(':', 2)
          sname ||= scode; sname.strip!
          scode= scode.to_code
          if scode=="role"
            gma_module.update_attribute :role, sname
            next
          end
          if scode.downcase=="link"
            role= get_option_xml("role", s) || ""
            rule= get_option_xml("rule", s) || ""
            gma_service= Gmindapp::Service.find_or_create_by :module_code=> gma_module.code, :code=> scode, :name=> sname
            gma_service.update_attributes :xml=>s.to_s, :name=>sname,
              :list=>listed(s), :secured=>secured?(s),
              :module_id=>gma_module.id, :seq => seq,
              :confirm=> get_option_xml("confirm", xml),
              :role => role, :rule => rule, :uid=> gma_service.id.to_s
            seq += 1
            protected_services << gma_service.uid
          else
            # normal service
            step1 = s.elements['node']
            role= get_option_xml("role", step1) || ""
            rule= get_option_xml("rule", step1) || ""
            gma_service= Gmindapp::Service.find_or_create_by :module_code=> gma_module.code, :code=> scode
            gma_service.update_attributes :xml=>s.to_s, :name=>sname,
              :list=>listed(s), :secured=>secured?(s),
              :module_id=>gma_module.id, :seq => seq,
              :confirm=> get_option_xml("confirm", xml),
              :role => role, :rule => rule, :uid=> gma_service.id.to_s
            seq += 1
            protected_services << gma_service.uid
          end
        end
      end
      Gmindapp::Module.not_in(:uid=>protected_modules).delete_all
      Gmindapp::Service.not_in(:uid=>protected_services).delete_all
    end
    def get_app
      dir= "#{Rails.root}/app/gmindapp"
      f= "#{dir}/index.mm"
      t= REXML::Document.new(File.read(f).gsub("\n","")).root
      recheck= true ; first_pass= true
      while recheck
        recheck= false
        t.elements.each("//node") do |n|
          if n.attributes['LINK'] # has attached file
            if first_pass
              f= "#{dir}/#{n.attributes['LINK']}"
            else
              f= n.attributes['LINK']
            end
            next unless File.exists?(f)
            tt= REXML::Document.new(File.read(f).gsub("\n","")).root.elements["node"]
            make_folders_absolute(f,tt)
            tt.elements.each("node") do |tt_node|
              n.parent.insert_before n, tt_node
            end
            recheck= true
            n.parent.delete_element n
          end
        end
        first_pass = false
      end
      return t
    end
    def controller_exists?(modul)
      File.exists? "#{Rails.root}/app/controllers/#{modul}_controller.rb"
    end
    def dup_hash(a)
      h = Hash.new(0)
      a.each do |aa|
        h[aa] += 1
      end
      return h
    end
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
    
    module FormBuilder
      def date_field(method, options = {})
        default= self.object.send(method) || Date.today
        data_options= ({"mode"=>"calbox"}).merge(options)
        %Q(<input name='#{self.object_name}[#{method}]' id='#{self.object_name}_#{method}' value='#{default.strftime("%F")}' type='date' data-role='datebox' data-options='#{data_options.to_json}'>).html_safe
      end
    end
  end
end

class String
  def comment?
    self[0]==35 # check if first char is #
  end
  def to_code
    s= self.dup
#    s.downcase!
#    s.gsub! /[\s\-_]/, ""
#    s
    code, name = s.split(':')
    code.downcase.strip.gsub(' ','_').gsub(/[^#_\/a-zA-Z0-9]/,'')
  end
end
