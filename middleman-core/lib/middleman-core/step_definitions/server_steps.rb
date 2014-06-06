# encoding: UTF-8

require 'rack/mock'

Given /^a clean server$/ do
  @initialize_commands = []
end

Given /^"([^\"]*)" feature is "([^\"]*)"$/ do |feature, state|
  @initialize_commands ||= []

  if state == 'enabled'
    @initialize_commands << lambda { activate(feature.to_sym) }
  end
end

Given /^"([^\"]*)" feature is "enabled" with "([^\"]*)"$/ do |feature, options_str|
  @initialize_commands ||= []

  options = eval("{#{options_str}}")

  @initialize_commands << lambda { activate(feature.to_sym, options) }
end

Given /^"([^\"]*)" is set to "([^\"]*)"$/ do |variable, value|
  @initialize_commands ||= []
  @initialize_commands << lambda {
    config[variable.to_sym] = value
  }
end

Given /^the Server is running$/ do
  root_dir = File.expand_path(current_dir)

  if File.exists?(File.join(root_dir, 'source'))
    ENV['MM_SOURCE'] = 'source'
  else
    ENV['MM_SOURCE'] = ''
  end

  ENV['MM_ROOT'] = root_dir

  initialize_commands = @initialize_commands || []

  @server_inst = Middleman::Application.server.inst do
    app.initialized do
      initialize_commands.each do |p|
        config_context.instance_exec(&p)
      end
    end
  end

  app_rack = @server_inst.class.to_rack_app
  @browser = ::Rack::MockRequest.new(app_rack)
end

Given /^the Server is running at "([^\"]*)"$/ do |app_path|
  step %Q{a fixture app "#{app_path}"}
  step %Q{the Server is running}
end

When /^I go to "([^\"]*)"$/ do |url|
  @last_response = @browser.get(URI.escape(url))
end

Then /^going to "([^\"]*)" should not raise an exception$/ do |url|
  last_response = nil
  lambda {
    last_response = @browser.get(URI.escape(url))
  }.should_not raise_exception
  @last_response = last_response
end

Then /^the content type should be "([^\"]*)"$/ do |expected|
  @last_response.content_type.should start_with(expected)
end

Then /^I should see "([^\"]*)"$/ do |expected|
  @last_response.body.should include(expected)
end

Then /^I should see '([^\']*)'$/ do |expected|
  @last_response.body.should include(expected)
end

Then /^I should see:$/ do |expected|
  @last_response.body.should include(expected)
end

Then /^I should not see "([^\"]*)"$/ do |expected|
  @last_response.body.should_not include(expected)
end

Then /^I should see "([^\"]*)" lines$/ do |lines|
  @last_response.body.chomp.split($/).length.should == lines.to_i
end
