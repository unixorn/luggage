module Angelia
    # Hold individual alert messages, these get dumped using YAML to
    # disk in the spool.
    #
    # Recipients are instances of Angelia::Recipient.
    class Message
        attr_accessor :recipient, :subject, :message, :vars, :msgmode

        # Creates a new message.
        #
        # If message is not "" then this will be the body of the
        # alert regardless of anything else.
        #
        # If you specify either nagios-host or nagios-service it's
        # assumed this is running under nagios and all the NAGIOS_*
        # environment variables are available, these will be used in
        # conjunction with templates to create the message bodies.
        #
        # If anything prevents the message from being built such as
        # a corrupt combinarion of options etc you'll receive an
        # Angelia::CorruptMessage exception.
        def initialize(recipient, message, subject, mode)
            @recipient = Angelia::Recipient.new(recipient)
            @message = message
            @subject = subject
            @msgmode = mode

            Angelia::Util.debug("New message created for : recipient: #{@recipient.protocol}:#{@recipient.user} in mode #{@msgmode}")

            if mode =~ /^nagios/ && message == ""
                unless ENV["NAGIOS_DATE"]
                    Angelia::Util.debug("No ENV[NAGIOS_DATE] variable and message == ''")

                    raise(Angelia::CorruptMessage, "Must be run from within nagios")
                end

                @vars = {}

                ENV.each do |k, v|
                    if k =~ /^NAGIOS_(.+)/
                        @vars[$1] = v
                    end
                end
            end

            # If someone passes message specifically into us just use that, else
            # use the templates for each protocol and mode
            makemsg if @message == ""
        end

        # Creates the message, if this is a nagios message pass all the NAGIOS_*
        # variables into a binding and use this with ERB to build the message body.
        #
        # Temlates should be called <protocol>-<host|service>.erb in the templatedir
        # as configured using Angelia::Config
        def makemsg
            # if this is a nagios template, use the ENV vars to build the template
            # else just use whatever message was passed to the object
            if @msgmode =~ /^nagios-(.+)/
                type = $1
                templatefile = "#{Angelia::Util.config.templatedir}/#{recipient.protocol}-#{type}.erb"
                Angelia::Util.debug("Creating message body based on template #{templatefile}")

                # create a binding and inject the NAGIOS_* vars into it, we'll use the binding
                # later on in the template so the template has access to these variables without
                # needing to do @vars[HOSTNAME] for example, just HOSTNAME would work
                b = binding
                @vars.each do |k, v|
                    eval("#{k} = @vars[\"#{k}\"]", b)
                end


                if File.exists? templatefile
                    template = File.readlines(templatefile).join
                    renderer = ERB.new(template, 0, "<>")
                    @message = renderer.result(b)
                else
                    raise(Angelia::CorruptMessage, "Cannot find template #{templatefile}")
                end
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
