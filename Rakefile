# frozen_string_literal: true

require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task(default: :spec)
rescue LoadError
  warn("Couldn't load RSpec gem")
end

# Check the syntax of all Ruby files
task :syntax do
  sh 'find . -name *.rb -type f -exec ruby -c {} \; -exec echo {} \;'
end
