require 'rubygems'
require 'clickatell'

module Angelia::Plugin
    # Plugin that sends SMS messages via Clickatell, needs the Clickatell gem from
    # http://clickatell.rubyforge.org/
    #
    # plugin = Clickatell
    # plugin.Clickatell.user = xxx
    # plugin.Clickatell.password = yyyyy
    # plugin.Clickatell.apikey = 123
    # plugin.Clickatell.senderid = 123
    #
    # You can then send sms to people using clickatell://44xxxxxxxxxxx
    #
    # If there's a submission problem this plugin will wait 2 minutes before
    # trying again, just to not be hitting their API too hard
    class Clickatell
        def initialize(config)
            Angelia::Util.debug("Creating new insance of Clickatell plugin")

            @config = config
            @lastfailure = 0
        end

        def self.register
            Angelia::Util.register_plugin("clickatell", "Clickatell")
        end

        def send(recipient, subject, msg)
            Angelia::Util.debug("#{self.class} Sending message to '#{recipient}' with subject '#{subject}' and body '#{msg}'")

            apikey = @config["apikey"]
            user = @config["user"]
            password = @config["password"]
            senderid = @config["senderid"]

            # if we had a failed delivery in the last 10 minutes do not try to send a new message
            if Time.now.to_i - @lastfailure.to_i > 120
                begin
                    ct = ::Clickatell::API.authenticate(apikey, user, password)
                    res = ct.send_message(recipient, msg, {:from => senderid})
                    @lastfailure = 0

                rescue Clickatell::API::Error => e
                    @lastfailure = Time.now
                    raise "Unable to send message: #{e}"

                rescue Exception => e
                    @lastfailure = Time.now
                    raise(Angelia::PluginConnectionError, "Unhandled issue sending alert: #{e}")
                end
            else
                raise(Angelia::PluginConnectionError, "Not delivering message, we've had failures in the last 2 mins")
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
