require 'rspec/expectations'
require 'rspec/core'
require 'heroku'
require 'heroku/command'
require 'restclient'
lib_path = File.expand_path(File.dirname(__FILE__) + "/../lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

def not_in_editor?
  !(ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM'))
end

Rspec.configure do |c|
  c.run_all_when_everything_filtered = true
  c.filter_run :focused => true
  c.alias_example_to :fit, :focused => true
  c.color_enabled = not_in_editor?
  c.mock_with :rr
end
