require'rubygems'
require 'boxcar_api'

module Angelia::Plugin
    # Plugin to deliver push notifications to iPhones and iPads using http://boxcar.io
    #
    # You need to sign up for a service provider with them and convigure the plugin:
    #
    # plugin = Boxcar
    # plugin.Boxcar.apikey = xxx
    # plugin.Boxcar.apisecret = yyyyy
    # plugin.Boxcar.serviceid = 123
    # plugin.Boxcar.sender = you
    #
    # Get the serviceid from your Boxcar provider page - see the url.  The sender is
    # a simple string that will be the sender of the notification
    #
    # You can then send emails to subscribed people using boxcar://their@email
    class Boxcar
        def initialize(config)
            Angelia::Util.debug("Creating new insance of Boxcar plugin")

            @config = config
            @lastfailure = 0
        end

        def self.register
            Angelia::Util.register_plugin("boxcar", "Boxcar")
        end

        def send(recipient, subject, msg)
            Angelia::Util.debug("#{self.class} Sending message to '#{recipient}' with subject '#{subject}' and body '#{msg}'")

            apikey = @config["apikey"]
            apisecret = @config["apisecret"]
            serviceid = @config["serviceid"]
            sender = @config["sender"]

            begin
                bp = BoxcarAPI::Provider.new(apikey, apisecret)
                res = bp.notify(recipient, msg, sender, nil, serviceid)

                if res.code == 200
                    return 0
                else
                    raise(Angelia::PluginConnectionError, "Could not send message, api code: #{res.code}")
                end
            rescue Exception => e
                raise(Angelia::PluginConnectionError, "Unhandled issue sending alert: #{e}")
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
