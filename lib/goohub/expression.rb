# coding: utf-8
require 'json'
require 'uri'
require 'yaml'
require 'mail'
require 'net/https'
require 'time'

################################################################
# Abstract Expression
###############################################################
module Goohub
  module Expression
    @@reserved_word = ["today", "everyday", "weekday", "holiday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]



    ################################################################
    #Non-Terminal Expression
    ################################################################
    class Or
      def initialize(expression1, expression2)
        @expression1 = expression1
        @expression2 = expression2
      end

      def evaluate(e)
        result1 = @expression1.evaluate(e)
        result2 = @expression2.evaluate(e)
        return (result1 or result2)
      end
    end

    class And
      def initialize(expression1, expression2)
        @expression1 = expression1
        @expression2 = expression2
      end

      def evaluate(e)
        result1 = @expression1.evaluate(e)
        result2 = @expression2.evaluate(e)
        return (result1 and result2)
      end
    end

    class Not
      def initialize(expression)
        @expression = expression
      end

      def evaluate(e)
        return (not @expression.evaluate(e))
      end
    end

    ################################################################
    # Terminal Expression for Filter
    ################################################################
    class EventString
      def initialize(arg)
        # p "#{arg}" #for debug
        @arg = arg
        @arg = to_regexp(arg) if arg.match(/\/.*\//)
      end

      def evaluate(e)
        str = read(e)
        # p "evaluate: " + str + ", #{@arg}"# for debug
        if str[@arg] then
          return true
        else
          return false
        end
      end

      def read(e)
        # p "Not implemented"
      end

      def write(e, str)
        # p "Not implemented"
      end

      def format_tag(e)
        # p "Not implemented"
      end

      private

      def to_regexp(arg)
        return Regexp.new(arg.delete("/"))
      end
    end


    class Summary < EventString
      def read(e)
        str = e.summary
        return str
      end

      def write(e, str)
        e.summary = str
      end

      def format_tag(e)
        e.summary.gsub!("就活","")
        e.summary.gsub!(/,|，/,"")
      end
    end

    class Location < EventString
      def read(e)
        return e.location
      end

      def write(e, str)
        e.location = str
      end
    end

    class Description < EventString
      def read(e)
        return e.description
      end

      def write(e, str)
        e.description = str
      end
    end

    class EventDate
      def initialize(arg)
        @arg_type = type(arg)
        @arg = format(arg)
      end

      def evaluate(e)
        date = set_date(e)
        # p "evaluate: " + "#{date}" + ", #{@arg}"# for debug

        case @arg_type
        when :operator then
          operator = @arg[0]
          case operator
          when "newer"
            result = true if date < read(e)
          when "older"
            result = true if date > read(e)
          when "after"
            result = true if date <= read(e)
          when "before"
            result = true if date >= read(e)
          end
        # TODO
        when :range then
        when :reserved then
        end
        return result
      end

      private

      def type(arg)
        return :operator if arg.include?(":")
        return :range if arg.include?("..")
        @@reserved_word.each { |word|
          return :reserved if arg == word
        }
      end

      def format(arg)
        case type(arg)
        when :operator then
          arg.gsub!(" ", "")
          array = arg.partition(":")
          # TODO: YYYY-MM-DDは変換できるが，MM-DDは変換不可
          return [array[0], array[2]]

        when :range then
          arg.gsub!(" ", "")
          array = arg.partition("..")
          # TODO: YYYY-MM-DDは変換できるが，MM-DDは変換不可
          return [Time.parse(array[0]), Time.parse(array[2])]
        when :reserved then
          return arg
        end
      end
      # TODO: 全日とそうでない時の区別
      def set_date(e)
        if @arg[1].count("-") == 2
          return Time.parse(@arg[1])
        else
          return Time.new(read(e).year, read(e).month, read(e).day, @arg[1].partition("-")[0], @arg[1].partition("-")[2], 0, "+09:00")
        end
      end
    end# class EventDate

    class Dtstart < EventDate
      def read(e)
        return Time.parse(e.dtstart.to_s)
      end

      def write(e, dtstart)
        e.dtstart = dtstart
      end
    end

    class Dtend < EventDate
      def read(e)
        return Time.parse(e.dtstart.to_s)
      end

      def write(e, dtend)
        e.dtend = dtend
      end
    end



    ################################################################
    # Terminal Expression for Action
    ################################################################
    class Hide_event
      def evaluate(e)
        return nil
      end
    end

    class Replace
      def initialize(event_item, arg=nil)
        @event_item = event_item
        @arg = arg
      end

      def evaluate(e)
        node = Goohub::Parser::Filter.determine_terminal_expression([@event_item,"",""])
        @arg = convert_arg(@arg, node.read(e)) if @arg
        node.write(e, @arg)
        node.format_tag(e)
      end

      private

      def convert_arg(arg, str)
        if arg.include?("{#}") then
          arg.gsub!(/\{#\}/, str)
        end
        return arg
      end
    end

    class Hide < Replace
    end

    ################################################################
    # Terminal Expression for Outlet
    ################################################################
    class Outlet
      attr_accessor :sentence_items

      private

      def parse_event(event)
        @sentence_items = {}
        @sentence_items["summary"] =     event.summary
        @sentence_items["description"] = event.description
        @sentence_items["id"] =          event.id
        @sentence_items["start_time"] =  event.dtstart
        @sentence_items["end_time"] =    event.dtend
        @sentence_items["location"] =    event.location
        @sentence_items
      end

      def convert_sentence
        sentence = ""
        @sentence_items.each{ |key, value|
          sentence <<  "#{key}: #{value}\n"
        }
        sentence
      end

      def convert_google_event
        event =
          Google::Apis::CalendarV3::Event.new({
                                                summary: @sentence_items["summary"],
                                                start: {
                                                  date_time: @sentence_items["start_time"],
                                                },
                                                end: {
                                                  date_time: @sentence_items["end_time"],
                                                },
                                                location: @sentence_items["location"]
                                              })
        event
      end

      def set_settings
        settings_file_path = "settings.yml"
        @config = YAML.load_file(settings_file_path) if File.exist?(settings_file_path)
      end
    end# class Outlet



    class Stdout < Outlet
      def evaluate(e, client)
        parse_event(e)
        inform_stdout(convert_sentence)
      end

      private

      def inform_stdout(sentence)
        puts sentence
      end
    end

    class Google_calendar < Outlet
      def initialize(calendar_id)
        @calendar_id= calendar_id
      end

      def evaluate(e, client)
        parse_event(e)
        inform_calendar(convert_google_event, client)
        puts "Outlet Calendar: #{@calendar_id}"
      end

      private

      def inform_calendar(event, client)
        result = client.insert_event(@calendar_id, event)
      end
    end

    class Mailer < Outlet # Mail is used in gem 'mail', so in this case, use 'Mailer'
      def initialize(mail_address)
        @mail_address = mail_address
      end

      def evaluate(e, client)
        parse_event(e)
        inform_mail(convert_sentence)
        puts "Outlet Mail: #{@mail_address}"
      end

      private

      def inform_mail(sentence)
        set_settings
        # なぜか，インスタンス変数を直接mailのtoにつっこむと落ちるため，一度変数にうつす
        to = @mail_address
        address = @config['mail_address']
        password = @config['mail_password']
        mail = Mail.new do
          from     "#{address}"
          to       "#{to}"
          subject  "Goohub share event"
          body     "#{sentence}"
        end
        options = { :address               => "smtp.#{address.split('@')[1]}",
                    :port                  => 587,
                    :domain                => "#{address.split('@')[1]}",
                    :user_name             => "#{address.split('id')[0]}",
                    :password              => "#{password}",
                    :authentication        => :plain,
                    :enable_starttls_auto  => true  }

        mail.charset = 'utf-8'
        mail.delivery_method(:smtp, options)
        mail.deliver
      end

    end

    class Slack < Outlet
      def evaluate(e, client)
        parse_event(e)
        inform_slack(convert_sentence)
        puts "Outlet Slack"
      end

      private

      def inform_slack(sentence, options = {})
        payload = options.merge({text: sentence})
        set_settings
        incoming_webhook_url = ENV['INCOMING_WEBHOOK_URL'] || @config["slack_incoming_webhook_url"]
        uri = URI.parse(incoming_webhook_url)
        res = nil
        json = payload.to_json
        request = "payload=" + json
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          res = http.post(uri.request_uri, request)
        end
        return res
      end
    end# class Slack
  end# module Expression
end# module Goohub
