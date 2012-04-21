require 'gmindapp'
require 'gmindapp/helpers'

module Gmindapp
  require 'rails'
  class Railtie < Rails::Railtie
    initializer "testing" do |app|
      ActionController::Base.send :include, Gmindapp::Helpers
#      ApplicationHelper.send :include, Gmindapp::Helpers
#      ::ActionView::Base.send(:include, Sorted::ViewHelpers::ActionView)
    end
    rake_tasks do
      load "tasks/gmindapp.rake"
    end
  end
end

module ApplicationHelper
  include Gmindapp::Helpers
end
