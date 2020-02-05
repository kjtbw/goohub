module Goohub
  module Resource
    class TimestampCollection < Collection
      def initialize
        @raw_resource = Array.new
      end
      def each
        @raw_resource.each do |t|
          yield Goohub::Resource::Timestamp.new(t)
        end
      end

      def push(item)
        @raw_resource.push
      end

      def to_json
        @raw_resource.to_json
      end

      def dump
        @raw_resource
      end

      def print
        before_time = nil
        diff_time = 0.0
        total_time = 0.0
        summary = Array.new(10, 0.0)
        puts "############start puts time###############"
        @raw_resource.each_with_index do |t|
          t.print
          diff_time = t.time - before_time if before_time
          puts diff_time
          before_time = t.time
          summary[t.summary_number] = summary[t.summary_number] + diff_time if t.summary_number
          total_time = total_time + diff_time
        end
        summary.push(total_time)
        p summary
        puts "############end puts time###############"
      end
    end# class TimestampCollection
  end# module Resource
end# module Goohub
