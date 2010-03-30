require 'yaml'
require 'pp'
require 'fileutils'
require 'active_support'
require 'active_support/core_ext/module/attribute_accessors'

module Switches
  mattr_accessor :root_path
  class << self
    def config_dir
      @_config_dir ||= File.join root_path, 'config', 'switches'
    end
    def rake_path
      @_rake_path ||= File.join root_path, 'lib', 'tasks', 'switches.rake'
    end
    def capistrano_path
      @_capistrano_path ||= File.join config_dir, 'capistrano_tasks.rb'
    end
    def capistrano_load_path
      @_capistrano_load_path ||= capistrano_path.gsub "#{root_path}/", '' # => 'config/switches/capistrano_tasks.rb'
    end
    def capfile_path
      @_capfile_path ||= File.join root_path, 'Capfile'
    end
    def current_path
      @_current_path ||= File.join config_dir, 'current.yml'
    end
    def default_path
      @_default_path ||= File.join config_dir, 'default.yml'
    end
    def backup_path
      @_backup_path ||= File.join config_dir, 'backup.yml'
    end
    def transaction_pid_path
      @_transaction_pid_path ||= File.join config_dir, 'transaction.pid'
    end
    
    def dump(method)
      if ENV['SWITCHES_XML'] == 'true'
        puts send(method).to_xml
      else
        pp send(method)
      end
    end
    
    def say(str)
      $stderr.puts "[SWITCHES GEM] #{str.gsub "#{root_path}/", ''}"
    end
    
    def setup
      say "Making #{config_dir}."
      FileUtils.mkdir_p config_dir
      
      if File.exists? default_path
        say "Not putting an example default.yml into #{default_path} because you already have one."
      else
        say "Putting an example default.yml into #{default_path}."
        File.open(default_path, 'w') { |f| f.write({ 'quick_brown' => true, 'fox_jumps' => false }.to_yaml) }
      end
      
      say "Refreshing gem-related Rake tasks at #{rake_path}."
      FileUtils.cp File.join(File.dirname(__FILE__), 'tasks', 'switches.rake'), rake_path
      
      say "Refreshing gem-related Capistrano tasks at #{capistrano_path}."
      FileUtils.cp File.join(File.dirname(__FILE__), 'tasks', 'capistrano_tasks.rb'), capistrano_path
      
      needs_append = false
      if not File.exists?(capfile_path)
        say "Creating a Capfile and including our tasks in it."
        needs_append = true
        FileUtils.touch capfile_path
      elsif old_capfile = IO.read(capfile_path) and old_capfile.include?(capistrano_load_path)
        say "Found a Capfile that already includes our tasks. Great!"
      else
        say "I'm going to add a line to your existing Capfile. Sorry if I break anything!"
        needs_append = true
      end
      
      File.open(capfile_path, 'a') do |f|
        say "Appending a line that loads our Capistrano tasks to your Capfile."
        f.write "\n# Added by switches gem #{Time.now}\nload '#{capistrano_load_path}'\n"
      end if needs_append
      
      say "Don't forget to:"
      say "* git add #{default_path}"
      say "* git add #{rake_path}"
      say "* git ignore #{capistrano_path}"
      say "* git ignore #{current_path}"
      say "You can refresh the gem tasks with Switches.setup. It won't touch anything else."
    end
    
    # taken from ActiveSupport::StringInquirer
    def method_missing(method_name, *args)
      suffix = method_name.to_s[-1,1]
      key = method_name.to_s[0..-2]
      
      if suffix == "?"
        if current.has_key?(key)
          current[key]      # set, so could be true or false
        else
          false             # unset, so always false
        end
      elsif suffix == "="
        current[key] = args.first
        # TEMPORARY since we're not doing a write_current here
      else
        super
      end
    end
    
    def default
      return @_default unless @_default.nil?
      # say "file system activity #{default_path}"
      resolve_transaction!
      @_default = YAML.load(IO.read(default_path))
      @_default.stringify_keys!
    rescue Errno::ENOENT
      say "Couldn't read defaults from #{default_path}."
      say "You probably want to run \"./script/runner 'Switches.setup'\"."
      raise $!
    end
    
    def current
      return @_current unless @_current.nil?
      resolve_transaction!
      if File.exist?(current_path)
        # say "file system activity #{current_path}"
        @_current = YAML.load(IO.read(current_path))
        @_current.stringify_keys!
      else
        @_current = default.dup
      end
      @_current
    end
    
    def diff
      retval = {}
      current.inject(retval) do |memo, ary|
        k, current_v = ary
        default_v = default[k]
        memo[k] = "#{default_v.nil? ? 'nil' : default_v} => #{current_v.nil? ? 'nil' : current_v}" if default_v != current_v
        memo
      end
      default.inject(retval) do |memo, ary|
        k, default_v = ary
        current_v = current[k]
        memo[k] = "#{default_v.nil? ? 'nil' : default_v} => #{current_v.nil? ? 'nil' : current_v}" if default_v != current_v
        memo
      end
      retval
    end
        
    def turn_off(name)
      name = name.to_s
      current[name] = false
      write_current
    end
    
    def turn_on(name)
      name = name.to_s
      current[name] = true
      write_current
    end
    
    def clear(name)
      name = name.to_s
      current.delete name
      write_current
    end
    
    def reset
      FileUtils.rm_f current_path
      @_current = nil
    end
    
    def backup
      write_current
      start_transaction!
      # say "file system activity #{backup_path}"
      FileUtils.cp current_path, backup_path
    end
    
    def restore
      if File.exist?(backup_path)
        FileUtils.mv backup_path, current_path
      else
        raise ArgumentError, "#{backup_path} doesn't exist."
      end
      end_transaction!
      @_current = nil
    end
    
    def write_current
      current # load it first!
      File.open(current_path, 'w') { |f| f.write current.stringify_keys.to_yaml }
    end
    
    def transaction_pid
      # say "file system activity #{transaction_pid_path}"
      IO.readlines(transaction_pid_path).first.chomp.to_i if File.exists?(transaction_pid_path)
    end
    
    def resolve_transaction!
      if transaction_pid.present? and transaction_pid != Process.pid
        say "Resolving... calling restore"
        restore
      end
    end
    
    def start_transaction!
      resolve_transaction!
      say "Starting transaction"
      File.open(transaction_pid_path, 'w') { |f| f.write Process.pid }
    end
    
    def end_transaction!
      say "Finishing transaction"
      FileUtils.rm_f transaction_pid_path
    end
  end
end
