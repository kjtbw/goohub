# coding: utf-8

class GoohubCLI < Clian::Cli
  desc "read TYPE", "Read DB by TYPE"
  option :name , :default => nil, :desc =>"specify table type"
  long_desc <<-LONGDESC
TYPE is filters, actions, outlets, and funnels

If you set name , read name colum by TYPE

If you not set name, default name is `nil`, and list all colum by TYPE
LONGDESC



  def read(type)
    kvs = Goohub::DataStore.create(:redis, {:host => "localhost", :port => "6379".to_i, :db => "0".to_i})
    if options[:name] == nil then
      puts "All #{type} names\n---"
      table = JSON.parse(kvs.load("#{type}"))
      table.each { |colum|
        puts colum["name"]
      }
      puts "---\n"
      return
    end

    case type
    when "filters" then
      filters = JSON.parse(kvs.load("filters"))
      filters.each { |f|
        @filter = Goohub::Filter.new(options[:name]) if f["name"]["#{options[:name]}"]
      }
      if @filters then
        puts "name:#{@filter.name}, condition:#{@filter.condition}"
      else
        puts "No filter match!"
      end

    when "actions" then
      actions = JSON.parse(kvs.load("actions"))
      actions.each { |a|
        @action = Goohub::Action.new(options[:name]) if a["name"]["#{options[:name]}"]
      }
      if @action then
        puts "name:#{@action.name}, modifier:#{@action.modifier}"
      else
        puts "No action match!"
      end

    when "outlets" then
      outlets = JSON.parse(kvs.load("outlets"))
      outlets.each { |o|
        @outlet = Goohub::Outlet.new(options[:name]) if o["name"]["#{options[:name]}"]
      }
      if @outlet then
        puts "name:#{@outlet.name}, informant:#{@outlet.informant}"
      else
        puts "No outlet match!"
      end

    when "funnels" then
      # TODO: add funnel read process
      puts "funnels"
    else
      puts "else"
    end
  end# def read
end# class GoohubCLI