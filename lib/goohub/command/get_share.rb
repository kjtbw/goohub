# coding: utf-8
require 'json'
require 'uri'
require 'yaml'
require 'mail'
require 'net/https'

class GoohubCLI < Clian::Cli
  desc "get_share CALENDAR_ID START_MONTH ( END_MONTH )", "Sharing updated events by funnel, between START_MONTH ( and END_MONTH ) in CALENDAR_ID"
  option :output, :default => "file", :desc => "specify output destination (file or redis:host:port:name)"

  long_desc <<-LONGDESC
    `goohub get_share` gets events between START_MONTH ( and END_MONTH ) found by CALENDAR_ID, output events which not stored DB, and share these events by funnel

CALENDAR_ID is detected by events command

You can change kind of sharing by making funnel

You can make funnel by write command, and then you can set FUNNEL_NAME into settins.yml'exec_funnel'

    When output is "redis", if other parameter( host or port or name ) is not set,

    host: "localhost", port: "6379", name: "0" is set by default.

LONGDESC

  def get_share(calendar_id, start_month, end_month="#{Date.today.year}-#{Date.today.month}")
    get_time("start_func")
    settings_file_path = "settings.yml"
    config = YAML.load_file(settings_file_path) if File.exist?(settings_file_path)
    funnels = config["exec_funnel"]

    start = Goohub::DateFrame::Monthly.new(start_month)
    output, host, port, db_name = options[:output].split(":")

    if !host or host == ""
      host = "localhost"
    end
    if !port or port == ""
      port = "6379"
    end
    if !db_name or db_name == ""
      db_name = "0"
    end

    start.each_to(end_month) do |frame|

      min = frame.to_s
      max = (frame.next_month - Rational(1, 24 * 60 * 60)).to_s # Calculate end of frame for Google Calendar API
      params = [calendar_id, frame.year.to_s, frame.month.to_s]
      get_time("before_get_list_event")
      raw_resource = client.list_events(params[0], time_max: max, time_min: min, single_events: true)
      get_time("end_get_list_event")
      events = Goohub::Resource::EventCollection.new(raw_resource)
      kvs = Goohub::DataStore.create(output.intern, {:host => host, :port => port.to_i, :db => db_name.to_i})

      get_time("before_check_DB")
      e_ids = []
      if kvs.load("#{calendar_id}-#{start_month}") then
        db_events = JSON.parse(kvs.load("#{calendar_id}-#{start_month}"))
        events.each do |e|
          exist_flag = false
          db_events["items"].each do |db_e|
            if e.summary.to_s == db_e["summary"] then
              exist_flag = true
              break
            end
          end
          e_ids << e.id if exist_flag == false
        end
      else
        events.each do |e|
          e_ids << e.id
        end
      end
      get_time("end_check_DB")

      #puts e_ids.join(' ')
      kvs.store("#{calendar_id}-#{start_month}", events.to_json) if e_ids[0] != nil
      i = 0
      for e in events do
        e = parse_event(e)
        for f in funnels do
          get_time("start_adapt_funnel_in_#{i}th_event")
          funnel = Goohub::Funnel.new(f)
          if funnel then
            filter = Goohub::Filter.new(funnel.filter_name)
            action = Goohub::Action.new(funnel.action_name)
            outlet = Goohub::Outlet.new(funnel.outlet_name)

            expr = Goohub::Parser::Filter.evaluate(filter.condition)
            if expr.evaluate(e)
              expr = Goohub::Parser::Action.evaluate(action.modifier)
              expr.evaluate(e)
              expr = Goohub::Parser::Outlet.evaluate(outlet.informant)
              get_time("before_outlet_evaluate_in_#{i}th_event")
              expr.evaluate(e, client)
              get_time("after_outlet_evaluate_in_#{i}th_event")
            end
          else
            puts "No funnel match!\nPlease check FUNNEL_NAME by read command"
          end
        end
        i = i + 1
      end
    end
    get_time("end_func")
    puts_time
  end


  private

  def parse_event(event)
    e = Goohub::Resource::Event.new(event)
    e.summary = event.dump.summary
    e.location = event.dump.location
    e.description = event.dump.description
    e.dtstart = event.dump.start.date_time
    e.dtend = event.dump.end.date_time
    return e
  end

  def caller_print()
    caller.each { |c|
      p c
    }
  end
end # class GoohubCLI
