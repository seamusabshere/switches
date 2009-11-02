# assumes you've got roles, deploy_to, rails_env

require 'pp'
require 'activesupport'
require 'zlib'

# basically { :a => 1, :b => 2 }.eql?({ :b => 2, :a => 1}) => true
class StrictComparableHash < Hash
  def eql?(other)
    self == other
  end

  # must return an integer or #eql? will be ignored by Comparable
  # assumes hash elements are strings
  # will break if a value is something else whose to_s varies randomly
  def hash
    Zlib.crc32(to_a.map(&:to_s).sort.to_s)
  end
end

# Hash.from_xml(a.gsub(/\n+/, ''))['hash']

namespace :s do
  %w{ c d on off clear reset backup restore default }.each do |cmd|
    task cmd.to_sym, :roles => lambda { roles.keys.map(&:to_s).grep(/app/).map(&:to_sym) } do
      upload File.join(File.dirname(__FILE__), '..', '..', 'lib', 'tasks', 'switches.rake'), File.join(deploy_to, 'current', 'lib', 'tasks', 'switches.rake')
      
      # download switches xml from servers
      raw_input = Hash.new
      run "cd #{deploy_to}/current; rake --silent s:#{cmd}#{"[#{ENV['ARG']}]" if ENV['ARG'].present?} RAILS_ENV=#{rails_env}; true" do |channel, stream, data|
        server = channel[:server]
        server_identifier = gfs ? server.host : "#{server.host}:#{server.port}".chomp(':')
        raw_input[server_identifier] ||= Array.new
        raw_input[server_identifier] << data
      end
      
      grouped_by_server = raw_input.inject(Hash.new) do |memo, ary|
        server_identifier, chunks = ary
        server_hash = Hash.from_xml(chunks.join.gsub(/\n+/, ''))['hash']
        memo[server_identifier] = server_hash.is_a?(Hash) ? StrictComparableHash[server_hash] : StrictComparableHash.new
        memo
      end
      
      first_server_switches = grouped_by_server.values.first

      # If GFS, all server switches will be the same---just output them
      if gfs
        pp first_server_switches
      else
        grouped_by_switches = grouped_by_server.inject(Hash.new) do |memo, ary|
          server_identifier, comparable_switches = ary
          memo[comparable_switches] ||= Array.new
          memo[comparable_switches] << server_identifier
          memo
        end
        if grouped_by_switches.keys.length > 1
          puts "Servers are different"
          pp grouped_by_switches.invert
          if grouped_by_switches.length == 2
            a, b = grouped_by_switches.invert.values
            puts
            puts "Difference is"
            pp a.diff(b)
          end
        else
          puts "Servers are the same"
          pp first_server_switches
        end
      end
    end
  end
end
