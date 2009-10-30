require 'rubygems'
require 'activesupport'
require 'yaml'
require 'fileutils'

# TODO not agnostic, expects RAILS_ROOT

module Switches
  CONFIG_DIR = File.join RAILS_ROOT, 'config', 'switches'
  TASKS_DIR = File.join RAILS_ROOT, 'lib', 'tasks'
  CURRENT_PATH = File.join CONFIG_DIR, 'current.yml'
  DEFAULT_PATH = File.join CONFIG_DIR, 'default.yml'
  BACKUP_PATH  = File.join CONFIG_DIR, 'backup.yml'
  
  class << self
    def setup
      $stderr.puts "Switches: making #{CONFIG_DIR}..."
      FileUtils.mkdir_p CONFIG_DIR
      $stderr.puts "... done."
      
      if File.exists? DEFAULT_PATH
        $stderr.puts "Switches: not putting an example default.yml into #{DEFAULT_PATH} because you already have one."
      else
        $stderr.puts "Switches: putting an example default.yml into #{DEFAULT_PATH}..."
        File.open(DEFAULT_PATH, 'w') { |f| f.write({ :example1 => true, :example2 => false }.to_yaml) }
        $stderr.puts "... done."
      end
      
      $stderr.puts "Switches: copying Rake tasks into #{TASKS_DIR}..."
      FileUtils.cp File.join(File.dirname(__FILE__), 'tasks', 'switches.rake'), TASKS_DIR
      $stderr.puts "... done."
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
      $stderr.puts "Switches: file system read #{DEFAULT_PATH}"
      @_default = YAML.load(File.read(DEFAULT_PATH))
    end
    
    def current
      return @_current unless @_current.nil?
      if File.exist?(CURRENT_PATH)
        $stderr.puts "Switches: file system read #{CURRENT_PATH}"
        @_current = YAML.load(File.read(CURRENT_PATH))
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
    
    def throw(name)
      name = name.to_s
      if current[name] == true
        turn_off name
      else
        turn_on name
      end
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
      File.open(CURRENT_PATH, 'w') { |f| f.write current.to_yaml }
    end
  end
end
