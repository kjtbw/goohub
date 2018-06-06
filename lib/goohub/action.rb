module Goohub
  class Action
    def initialize(action_id, sentence_items, client)
      @action_id = action_id
      @sentence_items = sentence_items
      @client = client
      @export_address = @action_id.partition(":")[2]
      puts @export_address
      action = Struct.new("ActionID", :application, :converter, :informant)
      @stdout = action.new("stdout", "convert_sentence", "inform_stdout")
      @slack = action.new("slack", "convert_sentence", "inform_slack")
      @calendar = action.new("calendar", "convert_google_event", "inform_google_calendar")
      @mail = action.new("mail", "convert_sentence", "inform_mail")
    end

    def apply
      puts make_sentence if @action_id == "stdout"
      apply_slack if @action_id == "slack"
      apply_calendar(@action_id.partition(":")[2]) if @action_id.partition(":")[0] == "calendar"
      apply_mail(@action_id.partition(":")[2]) if @action_id.partition(":")[0] == "mail"
    end

    private

    #####################################################
    ### root_methods
    #####################################################
    def apply_slack
      inform_slack(convert_sentence)
    end

    def apply_calendar(calendar_id)
      result = inform_calendar(calendar_id, convert_google_event)
    end

    def apply_mail(mail_address)
      inform_mail(mail_address, convert_sentence)
    end

    #####################################################
    ### process_methods
    #####################################################
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

    #####################################################
    ### export_methods
    #####################################################
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

    def inform_calendar(calendar_id, event)
      result = @client.insert_event(calendar_id, event)
    end

    def inform_mail(mail_address, sentence)
      set_settings
      address = @config['mail_address']
      password = @config['mail_password']
      mail = Mail.new do
        from     "#{address}"
        to       "#{mail_address}"
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

    #####################################################
    ### other methods
    #####################################################
    def set_settings
      settings_file_path = "settings.yml"
      @config = YAML.load_file(settings_file_path) if File.exist?(settings_file_path)
    end
  end# class Action
end# module Goohub
