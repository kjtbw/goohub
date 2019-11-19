dir = File.dirname(__FILE__) + "/command"

# Example: if you would add profile command,
# create profile.rb in command/
# and add `require` here like:
#    require "#{dir}/profile.rb"

require "#{dir}/init.rb"
require "#{dir}/auth.rb"
require "#{dir}/calendars.rb"
require "#{dir}/get_event.rb"
require "#{dir}/events.rb"
require "#{dir}/post_event.rb"
require "#{dir}/share.rb"
require "#{dir}/test.rb"
require "#{dir}/read.rb"
require "#{dir}/write.rb"
require "#{dir}/server.rb"
require "#{dir}/sinatra.rb"
require "#{dir}/get_share.rb"
