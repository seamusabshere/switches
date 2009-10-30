require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "switches"
    gem.summary = %Q{Turn on and off parts of your code based on yaml config files}
    gem.description = %Q{
Switches lets you turn on and off parts of your code from the commandline. There's a defaults.yml and a current.yml in the background.

For example:
>> Switches.campaign_monitor?
# => false

$ rake switches:on[campaign_monitor]

>> Switches.campaign_monitor?
# => true

$ rake switches:reset # goes back to default.yml
$ rake switches:diff  # shows diff b/w current.yml and default.yml
$ rake s:d            # alias for switches:diff

etc.

It's inspired by ActiveSupport's StringInquirer (e.g. Rails.development?) and traditional compile-time assertions.
    }
    gem.email = "seamus@abshere.net"
    gem.homepage = "http://github.com/seamusabshere/switches"
    gem.authors = ["Seamus Abshere"]
    gem.rubyforge_project = "switches"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_dependency "activesupport"
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "switches #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
