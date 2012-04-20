module Gmindapp
  module Helpers
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
