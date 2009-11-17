require 'yaml'
require 'rubygems'
require 'activesupport'

# TODO not agnostic, expects RAILS_ROOT

module Switches
  CONFIG_DIR = File.join RAILS_ROOT, 'config', 'switches'
  RAKE_PATH = File.join RAILS_ROOT, 'lib', 'tasks', 'switches.rake'
  CAPISTRANO_PATH = File.join CONFIG_DIR, 'capistrano_tasks.rb'
  CAPISTRANO_LOAD_PATH = CAPISTRANO_PATH.gsub "#{RAILS_ROOT}/", '' # => 'config/switches/capistrano_tasks.rb'
  CAPFILE_PATH = File.join RAILS_ROOT, 'Capfile'
  CURRENT_PATH = File.join CONFIG_DIR, 'current.yml'
  DEFAULT_PATH = File.join CONFIG_DIR, 'default.yml'
  BACKUP_PATH  = File.join CONFIG_DIR, 'backup.yml'
  
  class << self
    def say(str)
      $stderr.puts "[SWITCHES GEM] #{str.gsub "#{RAILS_ROOT}/", ''}"
    end
    
    def setup
      require 'fileutils'
      
      say "Making #{CONFIG_DIR}."
      FileUtils.mkdir_p CONFIG_DIR
      
      if File.exists? DEFAULT_PATH
        say "Not putting an example default.yml into #{DEFAULT_PATH} because you already have one."
      else
        say "Putting an example default.yml into #{DEFAULT_PATH}."
        File.open(DEFAULT_PATH, 'w') { |f| f.write({ 'quick_brown' => true, 'fox_jumps' => false }.to_yaml) }
      end
      
      say "Refreshing gem-related Rake tasks at #{RAKE_PATH}."
      FileUtils.cp File.join(File.dirname(__FILE__), 'tasks', 'switches.rake'), RAKE_PATH
      
      say "Refreshing gem-related Capistrano tasks at #{CAPISTRANO_PATH}."
      FileUtils.cp File.join(File.dirname(__FILE__), 'tasks', 'capistrano_tasks.rb'), CAPISTRANO_PATH
      
      needs_append = false
      if not File.exists?(CAPFILE_PATH)
        say "Creating a Capfile and including our tasks in it."
        needs_append = true
        FileUtils.touch CAPFILE_PATH
      elsif old_capfile = IO.read(CAPFILE_PATH) and old_capfile.include?(CAPISTRANO_LOAD_PATH)
        say "Found a Capfile that already includes our tasks. Great!"
      else
        say "I'm going to add a line to your existing Capfile. Sorry if I break anything!"
        needs_append = true
      end
      
      File.open(CAPFILE_PATH, 'a') do |f|
        say "Appending a line that loads our Capistrano tasks to your Capfile."
        f.write "\n# Added by switches gem #{Time.now}\nload '#{CAPISTRANO_LOAD_PATH}'\n"
      end if needs_append
      
      say "Don't forget to:"
      say "* git add #{DEFAULT_PATH}"
      say "* git add #{RAKE_PATH}"
      say "* git ignore #{CAPISTRANO_PATH}"
      say "* git ignore #{CURRENT_PATH}"
      say "You can refresh the gem tasks with Switches.setup. It won't touch anything else."
    end
    
    # taken from ActiveSupport::StringInquirer
    def method_missing(method_name, *args)
      suffix = method_name.to_s[-1,1]
      key = method_name.to_s[0..-2]
      
      if suffix == "?" and current.has_key?(key)
        current[key]
      elsif suffix == "="
        current[key] = args.first
        # TEMPORARY since we're not doing a write_current here
      else
        super
      end
    end
    
    def default
      return @_default unless @_default.nil?
      # say "file system activity #{DEFAULT_PATH}"
      @_default = YAML.load(IO.read(DEFAULT_PATH))
      @_default.stringify_keys!
    rescue Errno::ENOENT
      say "Couldn't read defaults from #{DEFAULT_PATH}."
      say "You probably want to run \"./script/runner 'Switches.setup'\"."
      raise $!
    end
    
    def current
      return @_current unless @_current.nil?
      if File.exist?(CURRENT_PATH)
        # say "file system activity #{CURRENT_PATH}"
        @_current = YAML.load(IO.read(CURRENT_PATH))
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
      FileUtils.rm_f CURRENT_PATH
      @_current = nil
    end
    
    def backup
      write_current
      # say "file system activity #{BACKUP_PATH}"
      FileUtils.cp CURRENT_PATH, BACKUP_PATH
    end
    
    def restore
      if File.exist?(BACKUP_PATH)
        FileUtils.mv BACKUP_PATH, CURRENT_PATH
      else
        raise ArgumentError, "#{BACKUP_PATH} doesn't exist."
      end
      @_current = nil
    end
    
    def write_current
      current # load it first!
      File.open(CURRENT_PATH, 'w') { |f| f.write current.stringify_keys.to_yaml }
    end
      # say "file system activity #{TRANSACTION_PID_PATH}"
  end
end
