class GoohubCLI < Clian::Cli
  desc "calendars", "List calendars"
  option :output, :default => "stdout", :desc => "specify output destination (stdout or file or redis:host:port:name)"

  def calendars
    #puts_time("start_func") # for eval
    raw_resource = client.list_calendar_lists()
    calendars = Goohub::Resource::CalendarCollection.new(raw_resource)
    #puts_time("end_get_calendar_list") # for eval

    output, host, port, db_name = options[:output].split(":")
    if output.include?("redis") and (!host or !port or !db_name)
      puts 'ERROR: "goohub events" was called with missing arguments for outputs'
      puts 'USAGE: If you want to store calendars_list to some kvs, you should set "kvs_name:hostname:port:db_name" to output'
      exit
    end

    case output
    when "stdout"
      calendars.each do |item|
        puts item.summary.to_s + "(" + item.id.to_s + ")"
      end
    when "file"
      puts "Store calendars_list to " + output
      kvs = Goohub::DataStore.create(:file)
      puts kvs.store("calendars", calendars.to_json)
    else
      # for redis
      puts "Store calendars_list to " + output
      print "Status: "
      kvs = Goohub::DataStore.create(output.intern, {:host => host, :port => port.to_i, :db => db_name.to_i})
      puts kvs.store("calendars", calendars.to_json)
    end
    #puts_time("end_func") #for eval
  end
end
