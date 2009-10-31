# assumes you've got roles, deploy_to, rails_env

require 'pp'
require 'activesupport'
require 'zlib'

# basically { :a => 1, :b => 2 }.eql?({ :b => 2, :a => 1}) => true
# assumes hash elements are basically strings
# will break if a value is an unordered hash that randomly to_s'es in different ways
class StrictHash < Hash
  def eql?(other)
    self == other
  end
  # has to be an integer or #eql? won't be used
  def hash
    Zlib.crc32(to_a.map(&:to_s).sort.to_s)
  end
end

SWITCH_SHORTHANDS = {
  'c' => 'list_current',
  'd' => 'diff',
  'on' => 'turn_on',
  'off' => 'turn_off'
}

REQUIRED_CAPISTRANO_VARIABLES = %w{
  deploy_to
  rails_env
  gfs
}

namespace :s do
  %w{ c d on off }.each do |switch_command|
    task switch_command.to_sym, :roles => lambda { roles.has_key?(:app_master) ? [ :app, :app_master ] : :app } do
      REQUIRED_CAPISTRANO_VARIABLES.each do |cvar|
        begin; send cvar; rescue; puts "[SWITCHES GEM] Please set :#{cvar} (probably in your cap deploy script)"; raise $!; end
      end
      raw = Hash.new
      switch_command = SWITCH_SHORTHANDS[switch_command] if SWITCH_SHORTHANDS.has_key?(switch_command)
      run "cd #{deploy_to}/current; rake --silent switches:#{switch_command}#{"[#{ENV['ARG']}]" if ENV['ARG'].present?} RAILS_ENV=#{rails_env}; true" do |channel, stream, data|
        unless data.starts_with?('Switches') #or data.starts_with?('(')
          server = channel[:server]
          key = gfs ? server.host : "#{server.host}:#{server.port}".chomp(':')
          raw[key] ||= Array.new
          raw[key] << data
        end
      end
      
      if gfs
        cooked = YAML.load raw.values.first.join
        pp cooked
      else
        sub_cooked = raw.inject(Hash.new) do |memo, ary|
          host, chunks = ary
          memo[host] = StrictHash[YAML.load(chunks.join)]
          memo
        end
        by_recipe = sub_cooked.inject(Hash.new) do |memo, ary|
          host, switches = ary
          memo[switches] ||= Array.new
          memo[switches] << host
          memo
        end
        if by_recipe.keys.length > 1
          puts "Servers have different switches"
          pp by_recipe.invert
          if by_recipe.length == 2
            a, b = by_recipe.invert.values
            puts "Difference is that #{by_recipe.values.first} has"
            pp a.diff(b)
          end
        else
          puts "Servers have the same switches"
          pp sub_cooked.to_a.first.last
        end
      end
    end
  end
end
