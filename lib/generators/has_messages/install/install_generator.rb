require 'generators/base'
require 'rails/generators/active_record'
require 'rails/generators/migration'
require 'rails/generators/generated_attribute'

module HasMessages
  module Generators
    class InstallGenerator < Base
      include Rails::Generators::Migration
      
      argument :arg, :type => :string, :required => true, :banner => 'USER MODEL NAME'
      class_option :destroy, :desc => 'Destroy all `has_messages` files', :type => :boolean, :default => false
      
      def generate_has_messages
        @model_path = "app/models/#{arg}.rb"
        @class_name = arg.classify
        if file_exists?(@model_path)
          if class_exists?(@class_name)
            if options.destroy?
              destroy_has_messages
            else
              install_required_gem
              must_load_lib_directory unless rails_3_1?
              copy_migrations
              copy_models_and_inject_code_into_user_model
              copy_controller_and_helper
              copy_views
              copy_assets
              add_routes
              readme "README"
            end
          else
            raise "#{@class_name} class are not exists!"
          end
        else
          raise "#{@model_path} are not exists in your current directory!"
        end
      rescue Exception => e
        print_notes(e.message,"error",:red)
      end
      
private 
      
      def install_required_gem
        gem "jquery-rails"
        generate("jquery:install") unless rails_3_1?
        gem "kaminari"
        gem "ancestry"
      end
      
      def copy_migrations
        migration_template "models/create_messages.rb", "db/migrate/create_messages.rb"
      end
      
      def copy_models_and_inject_code_into_user_model
        template "models/message.rb", "app/models/message.rb"
        copy_file "lib/has_messages.rb", "lib/has_messages.rb"
        
        inject_into_class @model_path, @class_name do
          "\n  has_many :messages" +
          "\n  include HasMessages\n"
        end
      end
      
      def copy_controller_and_helper
        template 'controllers/messages_controller.rb', 'app/controllers/messages_controller.rb'
        copy_file 'helpers/messages_helper.rb', 'app/helpers/messages_helper.rb'
      end
      
      def copy_views
        copy_file "views/_head.html.erb", "app/views/messages/_head.html.erb"
        copy_file "views/_messages.html.erb", "app/views/messages/_messages.html.erb"
        copy_file "views/_tabs_panel.html.erb", "app/views/messages/_tabs_panel.html.erb"
        copy_file "views/index.html.erb", "app/views/messages/index.html.erb"
        copy_file "views/index.js.erb", "app/views/messages/index.js.erb"
        copy_file "views/new.html.erb", "app/views/messages/new.html.erb"
        copy_file "views/show.html.erb", "app/views/messages/show.html.erb"
      end
      
      def copy_assets
        copy_asset 'assets/stylesheets/messages.css', 'public/stylesheets/messages.css'
        copy_asset 'assets/stylesheets/token-input-facebook.css', 'public/stylesheets/token-input-facebook.css'
        copy_asset 'assets/javascripts/messages.js', 'public/javascripts/messages.js'
        copy_asset 'assets/javascripts/jquery.tokeninput.js', 'public/javascripts/jquery.tokeninput.js'
      end
      
      def add_routes
        inject_into_file "config/routes.rb", :after => "Application.routes.draw do" do
          "\n\n\t resources :messages, :only => [:new, :create] do" +
          "\n\t   collection do" +
          "\n\t     get 'token' => 'messages#token', :as => 'token'" +
          "\n\t     post 'empty/:messagebox' => 'messages#empty', :as => 'empty'" +
          "\n\t     put 'update' => 'messages#update'" +
          "\n\t     get ':messagebox/show/:id' => 'messages#show', :as => 'show', :constraints => { :messagebox => /inbox|outbox|trash/ }" +
          "\n\t     get '(/:messagebox)' => 'messages#index', :as => 'box', :constraints => { :messagebox => /inbox|outbox|trash/ }" +
          "\n\t   end" +
          "\n\t end\n"
        end
      end
      
      def destroy_has_messages
        asking "Are you sure want to destroy the `has_messages` files?" do
          remove_file "app/models/message.rb"
          run('rm db/migrate/*_create_messages.rb')
          remove_file "app/controllers/messages_controller.rb"
          remove_file "app/helpers/messages_helper.rb"
          gsub_file @model_path, /has_many :messages/, ''
          gsub_file @model_path, /include HasMessages/, ''
          remove_file "lib/has_messages.rb"
          remove_dir "app/views/messages"
          remove_asset 'public/stylesheets/messages.css'
          remove_asset 'public/stylesheets/token-input-facebook.css'
          remove_asset 'public/javascripts/messages.js'
          remove_asset 'public/javascripts/jquery.tokeninput.js'
          gsub_file 'config/routes.rb', /resources :messages.*:constraints => { :messagebox => \/inbox|outbox|trash\/ }(\s*end){2}/m, ''
        end
      end
      
      # FIXME: Should be proxied to ActiveRecord::Generators::Base
      # Implement the required interface for Rails::Generators::Migration.
      def self.next_migration_number(dirname) #:nodoc:
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end
    end
  end
end
