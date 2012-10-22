# encoding: utf-8
class Param
  include Mongoid::Document
  validates_uniqueness_of :code
  # gmindapp begin
  include Mongoid::Timestamps
  field :code, :type => String
  field :pid, :type => String
  field :yearly, :type => Boolean
  field :description, :type => String
  # gmindapp end

  def self.get(code)
    p= where(:code=> code).first
    p.pid
  end
  def self.set(code, pid)
    p= where(:code=> code).first
    p.pid = pid.to_s
    p.save
  end
  def self.gen(code)
    p= where(:code=> code).first
    if p.yearly
      num, year = p.pid.split('/')
      y_now = (Time.now.year.to_i) -1957
      if year.to_i==y_now
        p.pid = "#{num.to_i+1}/#{y_now}"
      else # new year, restart counter
        p.pid = "1/#{y_now}"
      end
    else
      p.pid = (p.pid.to_i+1).to_s
    end
    p.save
    return p.pid
  end
end
