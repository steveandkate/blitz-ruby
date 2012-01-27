#simplecov
if ENV['coverage']
  require 'simplecov'
  SimpleCov.start do
       add_group "Core", "blitz"
  end
end

#requires
require 'rspec/core'
require 'blitz'
require 'rake'
require 'blitz/command/curl'