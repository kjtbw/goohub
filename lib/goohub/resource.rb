require 'forwardable'

module Goohub
  module Resource
    class Base
      extend Forwardable

      def initialize(raw_resource)
        @raw_resource = raw_resource
      end
    end # class Base

    class Collection
      extend Forwardable
      extend Enumerable

      def initialize(raw_resources)
        @raw_resources = raw_resources
      end

      # required to implement in subclass for enumerable methods
      def each
        raise 'Not implemented'
      end
    end # class Collection

    dir = File.dirname(__FILE__) + "/resource"

    autoload :Event,                "#{dir}/event.rb"
    autoload :Calendar,             "#{dir}/calendar.rb"
    autoload :Timestamp,            "#{dir}/timestamp.rb"
    autoload :EventCollection,      "#{dir}/event_collection.rb"
    autoload :CalendarCollection,   "#{dir}/calendar_collection.rb"
    autoload :TimestampCollection,  "#{dir}/timestamp_collection.rb"

  end # module Resource
end # module Goohub
