require 'time'

module Goohub
  module Resource
    class Timestamp < Base

      attr_accessor :name, :time, :summary_number
      def initialize(raw_resource, summary_number=nil)
        @flag = true
        @raw_resource = raw_resource
        @name = raw_resource
        @time = Time.now
        @summary_number = summary_number
      end

      def dump
        @raw_resource
      end

      def print
        puts "#{@name}: #{@time.iso8601(6)}"
      end

    end# class Timestamp
  end# module Resource
end# module Goohub
