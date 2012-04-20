require 'gmindapp'
require 'gmindapp/helpers'

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