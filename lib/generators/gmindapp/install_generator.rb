module Gmindapp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install Gmindapp component to existing Rails app "
      def self.source_root
        File.dirname(__FILE__) + "/templates"
      end
      def setup_gems
        # gem "nokogiri"
        gem "mechanize"
        # gem "rmagick", :require => "RMagick", :platform => "ruby"
        gem "geokit"
        gem 'rubyzip', :require => 'zip/zip'
        gem 'haml-rails'
        gem "mail"
        gem "prawn"
        gem "kaminari"
        # bug in mongo ruby driver 1.6.1, wait for mongoid 2.4.7
        gem "mongo", "1.5.1"
        gem "bson_ext", "1.5.1"
        gem "mongoid"
        gem "redcarpet"
        # gem 'maruku'
        gem 'wirble'
        gem 'therubyracer'
        gem 'bcrypt-ruby', '~> 3.0.0'
        gem 'omniauth-identity'
        gem_group :development, :test do
          # gem "ruby-debug"
          gem "debugger"
          gem "rspec"
          gem "rspec-rails"
        end
      end
      
      def setup_routes
        route "root :to => 'gmindapp#index'"
        # route "match 'gmindapp(/:action(/:id))(.:format)' => 'gmindapp'"
        route "match 'gmindapp/init/:module/:service' => 'gmindapp#init'"
        route "resources :identities"
        route "resources :sessions"
        route "match '/auth/:provider/callback' => 'sessions#create'"
        route "match '/auth/failure' => 'sessions#failure'"
        route "match '/logout' => 'sessions#destroy', :as => 'logout'"
        route "match ':controller(/:action(/:id))(.:format)'"
      end

      def setup_env
        create_file 'README.md', ''
        run "bundle install"
        generate "mongoid:config"
        generate "rspec:install"
        inject_into_file 'config/application.rb', :after => 'require "active_resource/railtie"' do
          "\nrequire 'mongoid/railtie'"
        end
        application do
%q{
  # gmindapp default
  config.generators do |g| 
    g.orm             :mongoid 
    g.template_engine :haml
    g.test_framework  :rspec 
    g.integration_tool :rspec
  end
}
        end
        initializer "gmindapp.rb" do
%q{
DEFAULT_TITLE = 'GMINDAPP'
DEFAULT_HEADER = 'GMINDAPP'
GMAP = true
}
        end

        inject_into_file 'config/environments/development.rb', :after => 'config.action_mailer.raise_delivery_errors = false' do
          "\n  config.action_mailer.default_url_options = { :host => 'localhost:3000' }"
        end
        inject_into_file 'config/environments/production.rb', :after => 'config.assets.compile = false' do
          "\n  config.assets.compile = true"
        end
        inject_into_file 'config/mongoid.yml', :after => '  # raise_not_found_error: true' do
          "\n  raise_not_found_error: false"
        end
      end
      
      def setup_mail
        copy_file "mail.rb","config/initializers/mail.rb"
        copy_file "lib/smtp_tls.rb","lib/smtp_tls.rb"
      end
      
      def setup_omniauth
        # gem 'bcrypt-ruby', '~> 3.0.0'
        # gem 'omniauth-identity'
        initializer "omniauth.rb" do
%q{
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity, :on_failed_registration=> lambda { |env|
    IdentitiesController.action(:new).call(env)
  }
end
}
        end
      end
      
      def setup_app
        inside("public") { run "mv index.html index.html.bak" }
        inside("app/controllers") { run "mv application_controller.rb application_controller.rb.bak" }
        inside("app/views/layouts") { run "mv application.html.erb application.html.erb.bak" }
        inside("app/helpers") { run "mv application_helper.rb application_helper.rb.bak" }
        inside("app/assets/javascripts") { run "mv application.js application.js.bak" }
        inside("app/assets/stylesheets") { run "mv application.css application.css.bak" }
        directory "app"
      end
      def gen_user
        copy_file "seeds.rb","db/seeds.rb"

        # identity = Identity.new
        # identity.name = "admin"
        # identity.email = "admin@test.com"
        # identity.password = "secret"
        # identity.password_confirmation = "secret"
        # identity.save
        # user= User.new
        # user.provider = "identity"
        # user.uid = identity.id.to_s
        # user.name = identity.name
        # user.email = identity.email
        # user.role = "M,A,D"
        # user.save
      end
    end
  end
end
