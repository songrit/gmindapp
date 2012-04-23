module Gmindapp
  module Helpers
    def process_services
      # todo: persist mm_md5
      xml= @app||get_app
      md5= Digest::MD5.hexdigest(xml.to_s)
      if session[:mm_md5]
        return if session[:mm_md5]==md5
      else
        session[:mm_md5]= md5
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
            gma_service= Gmindapp::Service.find_or_create_by :module=> module_code, :code=> scode, :name=> sname
            gma_service.update_attributes :xml=>s.to_s, :name=>sname,
              :listed=>listed(s), :secured=>secured?(s),
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
            gma_service= Gmindapp::Service.find_or_create_by :module=> module_code, :code=> scode
            gma_service.update_attributes :xml=>s.to_s, :name=>sname,
              :listed=>listed(s), :secured=>secured?(s),
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
      File.exists? "#{RAILS_ROOT}/app/controllers/#{modul}_controller.rb"
    end
    def dup_hash(a)
      h = Hash.new(0)
      a.each do |aa|
        h[aa] += 1
      end
      return h
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
