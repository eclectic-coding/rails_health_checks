# Rake task to run RSpec examples with a convenient name.
# Usage:
#   bundle exec rake spec
#   bundle exec rake rspec

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.rspec_opts = ['--format', 'documentation']
  end

  # Alias 'rspec' to 'spec' for convenience
  task :rspec => :spec

  # Make `rake` without args run specs (optional)
  # Enable default task so `rake` runs specs by default
  task :default => :spec
rescue LoadError => e
  # If rspec is not available, define a noop task that prints instructions
  desc 'Run RSpec (RSpec gem not installed)'
  task :spec do
    puts "RSpec is not available. Install development dependencies and run:"
    puts "  bundle install"
    puts "  bundle exec rake spec"
  end

  task :rspec => :spec
end

