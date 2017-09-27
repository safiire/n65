require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'test/test*.rb'
end


##  Check the syntax of all ruby files
task :syntax do |t|
  sh "find . -name *.rb -type f -exec ruby -c {} \\; -exec echo {} \\;"
end
