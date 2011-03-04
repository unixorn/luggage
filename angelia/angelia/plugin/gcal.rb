require 'rubygems'
require 'gcal4ruby'

# Notifier to add events to Google Calendar
#
# Configure like:
# plugin = Gcal
# plugin.Gcal.user = googleaccount@gmail.com
# plugin.Gcal.password = password
# plugin.Gcal.event_length = 1800
#
# This will make events of 30 minutes.
#
# You will need the GCal4Ruby gem. Message subject is the
# event title, msg body goes in the even description
#
# Recipients are gcal://<calendar name> which should map to
# an existing calendar in your account
module Angelia::Plugin
    class Gcal
        include GCal4Ruby

        def initialize(config)
            Angelia::Util.debug("Creating new instance of Gcal plugin")

            @config = config
        end

        def self.register
            Angelia::Util.register_plugin("gcal", "Gcal")
        end

        def send(recipient, subject, msg)
            Angelia::Util.debug("#{self.class} Sending message to '#{recipient}' with subject '#{subject}' and body '#{msg}'")

            user = @config["user"]
            pass = @config["password"]
            event_length = @config["event_length"].to_i || 1800

            raise "Need user and password" unless user && pass

            service = Service.new
            service.authenticate(user, pass)

            calendar = service.calendars.find {|c| c.title == recipient}

            event = Event.new(service, {:calendar => calendar, :title => subject, :start_time => Time.now, :end_time => Time.now + 600, :content => msg})
            event.save
        end
    end
end
