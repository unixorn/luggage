require 'rubygems'
require 'mail'

module Angelia::Plugin

    # A simple mailto plugin for sending email from nagios in a way
    # that is more maintainable/configurable than the nagios default
    # of 'printf | mail'
    class Mailto
        def initialize(config)
            Angelia::Util.debug("Creating new instance of Mailto plugin")

            @config = config
        end

        def self.register
            Angelia::Util.register_plugin("mailto", "Mailto")
        end

        def send(recipient, subject, msg)
            Angelia::Util.debug("#{self.class} Sending message to '#{recipient}' with subject '#{subject}' and body '#{msg}'")

            mail = Mail.new(msg)

            # Assume some defaults if not specified in the template.
            mail.to ||= recipient
            mail.subject ||= subject
            # TODO(sissel): would be nice to expose the config to the template
            # so we could set this there.
            mail.from ||= @config["from"]

            # If the mail doesn't parse, we probably won't have a body,
            # so let's assume the 'msg' is the body.
            if mail.body == ""
                mail.body = msg
            end

            Angelia::Util.debug("Mail contents:\n#{mail}")

            Mail.defaults.smtp @config["server"]
            mail.deliver!
        end
    end
end

# vi:shiftwidth=4:tabstop=4:expandtab:ai
