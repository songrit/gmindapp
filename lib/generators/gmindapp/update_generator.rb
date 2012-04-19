module Gmindapp
  module Generators
    class UpdateGenerator < Rails::Generators::Base
      desc "Update MVC from mind map"
      def self.source_root
        File.dirname(__FILE__) + "/templates"
      end

      def setup_env
        
        say " *** setup_env done", :green
      end
      
    end
  end
end
