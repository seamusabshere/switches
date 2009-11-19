require 'switches'

namespace :s do
  desc "List current"
  task :c do
    Switches.dump :current
  end

  desc "Diff current vs. default switches"
  task :d do
    Switches.dump :diff
  end

  desc "Turn on switch"
  task :on, :name do |t, args|
    Switches.turn_on args.name
    Switches.dump :current
  end

  desc "Turn off switch"
  task :off, :name do |t, args|
    Switches.turn_off args.name
    Switches.dump :current
  end

  desc "Clear switch"
  task :clear, :name do |t, args|
    Switches.clear args.name
    Switches.dump :current
  end

  desc "Reset all switches to defaults"
  task :reset do
    Switches.reset
    Switches.dump :current
  end

  desc "Backup all switches to defaults"
  task :backup do
    Switches.backup
    Switches.dump :current
  end

  desc "Restore all switches to defaults"
  task :restore do
    Switches.restore
    Switches.dump :current
  end

  desc "List default"
  task :default do
    Switches.dump :default
  end
end
