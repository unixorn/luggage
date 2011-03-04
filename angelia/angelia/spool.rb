module Angelia
    # Class that manages the spool, checks for new messages and delivers them.
    class Spool
        def initialize
            @config = Angelia::Util.config
        end

        # The main worker part of the class, this opens the spool dir, looks for new
        # messages and route them to the plugins via Angelia::Util.route
        #
        # Spool messages are YAML dumps of Angelia::Message objects.
        #
        # Expected problems should all result in a Angelia::CorruptMessage exception but
        # other exceptions should still be handled too.
        def run
            Angelia::Util.info("Angelia::Spool starting on #{@config.spooldir}")
            if File.exists?(@config.spooldir)
                while true
                    Dir.open(@config.spooldir) do |dir|
                        Angelia::Util.debug("Checking for files in spooldir")

                        dir.each do |file|
                            next if file =~ /^\.\.?$/
                            next unless file =~ /\.msg$/

                            spoolfile = "#{@config.spooldir}/#{file}"

                            begin
                                msg = YAML.load_file(spoolfile)


                                Angelia::Util.route(msg)

                                Angelia::Util.info("Message in #{spoolfile} to #{msg.recipient.protocol}://#{msg.recipient.user} has been delivered")

                                File.unlink("#{spoolfile}")

                            rescue Angelia::CorruptMessage => e
                                Angelia::Util.warn("Found a corrupt message in #{file}: #{e}, unlinking #{spoolfile}")
                                File.unlink("#{spoolfile}")

                            rescue Exception => e
                                Angelia::Util.warn("Could not send message in file #{file}: #{e}, will retry")
                            end
                        end
                    end

                    sleep 5
                end
            else
                raise("Spool directory (#{@config.spooldir}) does not exist")
            end
        end

        # Simple helper to create a Angelia::Message object and dump it
        # into the spool in a relatively safe way.
        def self.createmsg(message)
            name = "#{Time.now.to_f}-#{rand(10000000)}-#{$$}"
            config = Angelia::Util.config

            message.subject = "Angelia Alert" unless message.subject

            File.open("#{config.spooldir}/#{name}.part", 'w') do |f|
                YAML.dump(message, f)
            end

            File.rename("#{config.spooldir}/#{name}.part", "#{config.spooldir}/#{name}.msg")

            Angelia::Util.debug("New message created in the spool @ #{config.spooldir}/#{name}.msg")
        end
    end
end
# vi:tabstop=4:expandtab:ai
