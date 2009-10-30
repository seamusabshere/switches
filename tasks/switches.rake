require 'switches'

task :switches do
  Rake::Task['switches:default'].execute
end

namespace :s do
  task :c => 'switches:list_current'
  task :d => 'switches:diff'
  task :t, :name do |t, args|
    Rake::Task['switches:throw'].execute args
  end
  task :on, :name do |t, args|
    Rake::Task['switches:turn_on'].execute args
  end
  task :off, :name do |t, args|
    Rake::Task['switches:turn_off'].execute args
  end
end

namespace :switches do
  desc "List current and show instructions"
  task :default do
    puts <<-EOS

Throw a switch or add a new one with:
  rake switches:throw[SWITCH_NAME]
List current settings:
  rake switches:list_current
Test a particular switch:
  rake switches:test[SWITCH_NAME]
Show difference between current and default settings:
  rake switches:diff
Clear with:
  rake switches:remove[SWITCH_NAME]

... now listing current settings ...
    EOS
    Rake::Task['switches:list_current'].execute
  end
  
  # not called :default so it doesn't look like the default task
  desc "List default"
  task :list_default do
    puts Switches.default.to_yaml
  end
  
  desc "List current"
  task :list_current do
    puts Switches.current.to_yaml
  end
  
  desc "Test switch"
  task :test, :name do |t, args|
    puts Switches.send "#{args.name}?"
  end
  
  desc "Throw (toggle) switch"
  task :throw, :name do |t, args|
    Switches.throw args.name
    puts Switches.current.to_yaml
  end
  
  desc "Turn on switch"
  task :turn_on, :name do |t, args|
    Switches.turn_on args.name
    puts Switches.current.to_yaml
  end

  desc "Turn off switch"
  task :turn_off, :name do |t, args|
    Switches.turn_off args.name
    puts Switches.current.to_yaml
  end
  
  desc "Clear switch"
  task :clear, :name do |t, args|
    Switches.clear args.name
    puts Switches.current.to_yaml
  end
  
  desc "Diff current vs. default switches"
  task :diff do
    puts Switches.diff.to_yaml
  end
  
  desc "Reset all switches to defaults"
  task :reset do
    Switches.reset
    puts Switches.current.to_yaml
  end
  
  desc "Backup all switches to defaults"
  task :backup do
    Switches.backup
    puts Switches.current.to_yaml
  end
  
  desc "Restore all switches to defaults"
  task :restore do
    Switches.restore
    puts Switches.current.to_yaml
  end
end
