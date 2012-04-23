require 'gmindapp'
require 'gmindapp/helpers'
require 'gmindapp/elocal'

module Gmindapp
  require 'rails'
  class Railtie < Rails::Railtie
    initializer "testing" do |app|
      ActionController::Base.send :include, Gmindapp::Helpers
    end
    rake_tasks do
      load "tasks/gmindapp.rake"
    end
  end
end

module ApplicationHelper
  include Gmindapp::Helpers
  include Gmindapp::Elocal
end
