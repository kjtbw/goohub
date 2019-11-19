require 'forwardable'

module Goohub
  class Client
    class AuthorizationError < StandardError ; end

    extend Forwardable

    def_delegators :@client,
    :list_calendar_lists,
    :list_events,
    :get_event,
    :insert_event

    def initialize(config, app_name)
      authorizer = Clian::Authorizer.new(config.client_id,
                                         config.client_secret,
                                         Google::Apis::CalendarV3::AUTH_CALENDAR,
                                         config.token_store_path)
      time = Time.now
      puts "after_authorizer_new"
      puts time.iso8601(6)

      @client = Google::Apis::CalendarV3::CalendarService.new
      @client.client_options.application_name = app_name
      time = Time.now
      puts "before_authorizer_credentuals"
      puts time.iso8601(6)

      @client.authorization = authorizer.credentials(config.default_user)
      raise AuthorizationError.new unless @client.authorization
    end

  end # class Client
end # module Goohub
