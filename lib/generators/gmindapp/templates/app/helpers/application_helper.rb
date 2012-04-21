# -*- encoding : utf-8 -*-
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def process_services
    xml= get_app
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
    # GmaService.delete_all(["id NOT IN (?)",protected_services])
    # GmaModule.delete_all(["id NOT IN (?)",protected_modules])      
  end
  def gmodules_old
    [
      {:name=>'แบบสำรวจ', :url=>"/surveys"},
      {:name=>'สร้างแบบสำรวจ', :url=>"/surveys/new"},
      {:name=>'รายงาน', :url=>"/surveys/report"},
      {:name=>'** clear user', :url=>"/gmindapp/clear_users"},
      {:name=>'ทดสอบ', :url=>"/surveys/report", :confirm=>1}
    ]
  end
  def date_thai(d= Time.now, options={})
    y = d.year+543
    if options[:monthfull] || options[:month_full]
      mh= ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฏาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม']
    else
      mh= ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.']
    end
    if options[:time]
      d.day.to_s+" "+mh[d.month-1]+" "+y.to_s+" เวลา "+sprintf("%02d",d.hour.to_s)+":"+sprintf("%02d",d.min.to_s)
    else
      d.day.to_s+" "+mh[d.month-1]+" "+y.to_s
    end
  rescue
    ""
  end

  def fix_thai_year
    "<script type='text/javascript'>
    jQuery('select[id$=_1i] option').each(function(i) {
      this.text= parseInt(this.text)+543;
    });
    </script>".html_safe
  end

  def handle_gma_notice
    ""
  end
  def current_user
    @user ||= User.find(session[:user_id])
  end
  def i2date(t,f)
    Time.utc t["#{f}(1i)"],t["#{f}(2i)"],t["#{f}(3i)"]
  end
  def num_baht(n)
    return "-" unless n
    baht= n.to_s.split('.')[0]
    # return baht=="0" ? "-" : baht
    baht.to_i
  end
  def num_satang(n)
    return "-" unless n
    satang = ((n-n.to_i)*100).to_s
    # return satang=="0" ? "-" : satang
    satang.to_i
  end
  def nbsp(n)
    "&nbsp;"*n
  end
  def home_page?
    request.path=='/'
  end
  def num(n, precision= 0)
    return n==0 ? "-" : number_to_currency(n,:unit=>'', :precision=>precision)
  end
  def currency(n)
    return n==0 ? "-" : number_to_currency(n,:unit=>'')
  end
  alias_method(:to_currency, :currency)
  
  def title(page_title, show_title = true)
    @content_for_title = page_title.to_s
    @show_title = show_title
  end

  def show_title?
    @show_title
  end

  def stylesheet(*args)
    content_for(:head) { stylesheet_link_tag(*args.map(&:to_s)) }
  end

  def javascript(*args)
    args = args.map { |arg| arg == :defaults ? arg : arg.to_s }
    content_for(:head) { javascript_include_tag(*args) }
  end
  def thai_baht(amount)
    return "" unless amount
    number = amount.to_s
    txtnum1 = ['ศูนย์','หนึ่ง','สอง','สาม','สี่','ห้า','หก','เจ็ด','แปด','เก้า','สิบ']
    txtnum2 = ['','สิบ','ร้อย','พัน','หมื่น','แสน','ล้าน']
    number.gsub!(",","")
    number.gsub!(" ","")
    number.gsub!("บาท","")
    numbers = number.split(".")
    if(numbers.length>2)
      return "มีเครื่องหมาย '.' มากกว่า 1 ตัว"
    end
    strlen = numbers.first.length
    convert = ""
    0.upto(strlen-1) do |i|
      n = numbers.first[i].chr.to_i
      if (n!=0)
        if ( i == (strlen-1) and n == 1)
          convert = convert + "เอ็ด"
        elsif ( i == (strlen-2) and n == 2)
          convert = convert + "ยี่"
        elsif ( i == (strlen-2) and n == 1)
          convert = convert + ""
        else
          #       puts "n = #{n.chr.to_i}"
          convert = convert + txtnum1[n]
        end
        convert = convert + txtnum2[strlen-i-1]
      end
    end
    convert = convert + "บาท"
    if(numbers[1]=="0" or numbers[1]=="00" or numbers[1]=="" or numbers[1]==nil)
      convert = convert + "ถ้วน"
    else
      strlen = numbers[1].length
      if strlen==1
        numbers[1] = numbers[1]+"0"
        strlen = numbers[1].length
      end
      0.upto(strlen-1) do |i|
        n = numbers.last[i].chr.to_i
        if(n!=0)
          if(i==(strlen-1) and n==1)
            convert = convert + 'เอ็ด'
          elsif(i==(strlen-2) and n==2)
            convert = convert + 'ยี่'
          elsif(i==(strlen-2) and n==1)
            convert = convert + ''
          else
            convert = convert + txtnum1[n]
          end
          convert = convert + txtnum2[strlen-i-1]
        end
      end
      convert = convert + 'สตางค์'
    end
    return convert
  end
end

module ActionView
  module Helpers
    class FormBuilder
      def date_select_senior(method)
        date_select method, :default => 60.years.ago, :use_month_names=>THAI_MONTHS, :order=>[:day, :month, :year], :start_year=>Time.now.year-110, :end_year=>Time.now.year-60
      end
      def date_select_year(method, o={})
        date_select method, :default => o[:default], :use_month_names=>THAI_MONTHS, :order=>[:day, :month, :year], :start_year=>o[:start_year], :end_year=>o[:end_year]
      end
    end
  end
end
