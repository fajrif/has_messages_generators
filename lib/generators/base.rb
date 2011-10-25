require 'rails/generators/base'
require 'bundler'
require 'bundler/dsl'

module HasMessages
  module Generators
    class Base < Rails::Generators::Base #:nodoc:
      
      def self.source_root
        @_has_messages_source_root = File.expand_path(File.join(File.dirname(__FILE__), 'has_messages', generator_name, 'templates'))
      end
      
      def self.banner
        "rails generate has_messages:#{generator_name} #{self.arguments.map{ |a| a.usage }.join(' ')} [options]"
      end
      
protected
      
      def root_path(path)
        File.expand_path(File.join(File.dirname(__FILE__), 'has_messages', path))
      end
      
      def destination_path(path)
        File.join(destination_root, path)
      end
      
      def file_exists?(path)
        File.exist? destination_path(path)
      end
      
      def folder_exists?(path)
        File.directory? path
      end
      
      def class_exists?(class_name)
        klass = Rails.application.class.parent_name.constantize.const_get(class_name)
        return klass.is_a?(Class)
      rescue NameError
        return false
      end
      
      def extract(filepath,destinationpath,foldername)
        begin
          print_notes("Extracting #{filepath}")
          system("tar -C '#{destination_path(destinationpath)}' -xzf '#{root_path(filepath)}' #{foldername}/")
        rescue Exception => e
          raise e
        end
      end
      
      def asking(messages,&block)
        opt = ask("=> #{messages} [yes]")
        if opt == "yes" || opt.blank?
          yield
        end
      rescue Exception => e
        raise e
      end
      
      def print_notes(message,notes = "notes",color = :yellow)
        unless message.blank?
          puts        '', '='*80
          say_status  "#{notes}", "#{message}", color
          puts        '='*80, ''; sleep 0.5
        else
          puts "\n"
        end
      end
      
      def print_usage
        self.class.help(Thor::Base.shell.new)
        exit
      end
      
      def install_local_gem(name,version = nil)
        ::Bundler.with_clean_env do
          if version
            `gem install #{name} -v=#{version}`
          else
            `gem install #{name}`
          end
        end
        $? == 0 ? true : false
      rescue Exception => e
        raise e
      end
      
      def check_local_gem?(name,version = nil)
        ::Bundler.with_clean_env do
          if version
            `gem list #{name} -i -v=#{version}`
          else
            `gem list #{name} -i`
          end
        end
        $? == 0 ? true : false
      rescue Exception => e
        raise e
      end
      
      def refresh_bundle
        ::Bundler.with_clean_env do
          `bundle`
        end
      rescue Exception => e
        raise e
      end
      
      def set_application_config(&block)
        inject_into_class "config/application.rb", "Application" do
          yield
        end
      rescue Exception => e
        raise e
      end
      
      def must_load_lib_directory
        set_application_config do
          '  config.autoload_paths += %W(#{config.root}/lib)' + "\n"
        end
      end
      
      def gemfile_included?(name)
        ::Bundler.with_clean_env do
          `bundle show #{name}`
        end
        $?.exitstatus == 0 ? true : false
      rescue Exception => e
        raise e
      end
      
      def check_required_gems?(*names)
        names.each do |name|
          return false unless gemfile_included? name
        end
        true
      rescue Exception => e
        raise e
      end
      
      def rails_3_1?
        Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR >= 1
      end

      def copy_asset(source, *args, &block)
        if rails_3_1?
          if args.first =~ /^public/
            args.first.gsub!(/^public/,"app/assets")
          end
          if args.first.include?("javascripts/application.js") or args.first.include?("stylesheets/application.css")
            last_line = IO.readlines(args.first).last
            content = IO.read(File.expand_path(find_in_source_paths(source.to_s)))
            content.gsub!(/images/,"assets")
            inject_into_file args.first, :after => last_line do
              content
            end
            return
          end
        end
        copy_file(source, *args, &block)
      end
      
      def remove_asset(path, config={})
        if rails_3_1?
          if path =~ /^public/
            path.gsub!(/^public/,"app/assets")
          end
        end
        remove_asset(path, config)
      end
      
    end
  end
end

# => set callback on when calling +gem+
set_trace_func proc { |event, file, line, id, binding, classname| 
  ::Bundler.with_clean_env { `bundle` } if classname == Rails::Generators::Actions && id == :gem && event == 'return'
}