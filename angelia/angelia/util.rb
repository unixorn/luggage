require 'erb'
require 'logger'

module Angelia
    # exception for corrupt message files
    class Angelia::CorruptMessage < RuntimeError
    end

    # exception to be raised when a plugin can't connect to its transport
    class Angelia::PluginConnectionError < RuntimeError
    end

    # Simple utility class, these are all just class methods, you shouldn't need
    # to instantiate an instance of this.
    class Util
        @@plugins = {}
        @@config = {}
        @@logger = nil

        # Plugins should call this to register themselves as a handler for a specific protocol.
        #
        #    register_plugin("twitter", "Twitter")
        #
        # This will ensure that any twitter:// messages gets passed to the Angelia::Plugin::Twitter class.
        #
        # This method will instantiate new instances of each plugin and store it in a local variable.
        # No class should be calling plugins directly, to deliver messages use Angelia::Util.route
        def self.register_plugin(protocol, klass)
            Angelia::Util.info("Registering class 'Angelia::Plugin::#{klass}' for protocol '#{protocol}'")

            begin
                c = @@config.pluginconf(klass)

                k = eval("Angelia::Plugin::#{klass}.new(c)")
            rescue Angelia::PluginConnectionError => e
                Angelia::Util.warn("Angelia::Plugin::#{klass} could not connect to its provider, non critical runtime error")
            end

            @@plugins.store(protocol, k)
        end

        # Routes a message to the correct plugin, expects a Angelia::Message object.
        #
        # Routing will happen based on the properties of the Angelia::Recipient object
        # that is held inside a properly built Message object, the message, recipient etc
        # will be passed to the send method of the correct plugin.
        def self.route(msg)
            recipient = msg.recipient.user
            protocol = msg.recipient.protocol
            subject = msg.subject
            message = msg.message

            debug("Routing a message to #{protocol}://#{recipient}")

            if @@plugins.has_key? protocol
                @@plugins[protocol].send(recipient, subject, message)
            else
                Angelia::Util.error("Unknown protocol #{protocol}")
            end
        end

        # Saves the config, should be an instance of Angelia::Config
        def self.config=(config)
            @@config = config
        end

        # Returns the previously saved instance of Angelia::Config
        def self.config
            @@config
        end

        # logs at level INFO
        def self.info(msg)
            log(Logger::INFO, msg)
        end

        # logs at level WARN
        def self.warn(msg)
            log(Logger::WARN, msg)
        end

        # logs at level DEBUG
        def self.debug(msg)
            log(Logger::DEBUG, msg)
        end

        # logs at level FATAL
        def self.fatal(msg)
            log(Logger::FATAL, msg)
        end

        # logs at level ERROR
        def self.error(msg)
            log(Logger::ERROR, msg)
        end

        private

        # class to log messages, creates a new logger if its not been done yet
        # then logs a message prefixing it with the time
        def self.log(severity, msg)
            @@logger = Logger.new(@@config.logfile, 10, 102400) unless @@logger

            case @@config.loglevel
                when "info"
                    @@logger.level = Logger::INFO
                when "warn"
                    @@logger.level = Logger::WARN
                when "debug"
                    @@logger.level = Logger::DEBUG
                when "fatal"
                    @@logger.level = Logger::FATAL
                when "error"
                    @@logger.level = Logger::ERROR
                else
                    @@logger.level = Logger::INFO
            end

            @@logger.add(severity) { "#{caller[3]}: #{msg}" }
        end
    end
end

# vi:tabstop=4:expandtab:ai
