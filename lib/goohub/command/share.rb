# coding: utf-8
require 'json'
require 'uri'
require 'yaml'
require 'mail'
require 'net/https'

class GoohubCLI < Clian::Cli
  desc "share CALENDAR_ID EVENT_IDs", "Sharing calendar(CALENDAR_ID) of events(EVENT_IDs) by funnel"
  long_desc <<-LONGDESC
CALENDAR_ID and EVENT_IDs is detected by events command

You can set multiple EVENT_ID in EVENT_IDs

ex. $goohub share example_calendar_id@gmail.com event_id_1 event_id_2

You can change kind of sharing by making funnel

You can make funnel by write command, and then you can set FUNNEL_NAME into settins.yml'exec_funnel'
LONGDESC

  def share(calendar_id, *event_ids)
    settings_file_path = "settings.yml"
    config = YAML.load_file(settings_file_path) if File.exist?(settings_file_path)
    funnels = config["exec_funnel"]
    for event_id in event_ids do
      google_event = client.get_event(calendar_id, event_id)
      e = parse_google_event(google_event)

      for f in funnels do
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
            expr.evaluate(e, client)
          end
        else
          puts "No funnel match!\nPlease check FUNNEL_NAME by read command"
        end
      end
    end
  end

  private

  def parse_google_event(event)
    e = Goohub::Resource::Event.new(event)
    e.summary = event.summary
    e.location = event.location
    e.description = event.description
    e.dtstart = event.start.date_time
    e.dtend = event.end.date_time
    return e
  end
end# class GoohubCLI
