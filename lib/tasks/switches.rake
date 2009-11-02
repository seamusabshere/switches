require 'switches'

namespace :s do
  desc "List current"
  task :c do
    puts Switches.current.to_xml
  end

  desc "Diff current vs. default switches"
  task :d do
    puts Switches.diff.to_xml
  end

  desc "Turn on switch"
  task :on, :name do |t, args|
    Switches.turn_on args.name
    puts Switches.current.to_xml
  end

  desc "Turn off switch"
  task :off, :name do |t, args|
    Switches.turn_off args.name
    puts Switches.current.to_xml
  end

  desc "Clear switch"
  task :clear, :name do |t, args|
    Switches.clear args.name
    puts Switches.current.to_xml
  end

  desc "Reset all switches to defaults"
  task :reset do
    Switches.reset
    puts Switches.current.to_xml
  end

  desc "Backup all switches to defaults"
  task :backup do
    Switches.backup
    puts Switches.current.to_xml
  end

  desc "Restore all switches to defaults"
  task :restore do
    Switches.restore
    puts Switches.current.to_xml
  end

  desc "List default"
  task :default do
    puts Switches.default.to_xml
  end
end
