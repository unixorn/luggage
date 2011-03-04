module Angelia
    # Simple class to handle the configuring of the angelia.
    #
    # At present config files can look like this:
    #
    #    spooldir = /path/to/spooldirectory
    #    templatedir = /path/to/templatedirectory
    #    pidfile = /path/to/pidfile
    #    logfile = /path/to/lofile
    #    loglevel = warn|error|info|fatal|debug
    #    user = nagios
    #    group = nagios
    #    plugin = Xmpp
    #    plugin = Twitter
    #    plugin.Xmpp.username = foo
    #    plugin.Twitter.username = bar
    #
    # The plugin = lines tell it what plugin files to load and what
    # class names would be, each plugin can have configuration stored
    # here as well in the plugin.Pluginname.xxx bits.
    class Config
        attr_reader :spooldir, :plugins, :templatedir, :logfile, :loglevel,
                    :user, :group, :pidfile

        # Reads the config files and startup the plugins, if you want to skip
        # actually starting plugins, like while simply loading the config to
        # create new messages, set startplugins = false or nil etc
        def initialize(configfile, startplugins = true)
            @plugins = []
            @pluginconfig = {}
            @logfile = "/dev/stdout"
            @pidfile = "/var/run/angelia.pid"
            @loglevel = "warn"
            @user = nil
            @group = nil

            if File.exists?(configfile)
                File.open(configfile, "r").each do |line|
                    unless line =~ /^#|^$/
                        if (line =~ /(.+?)\s*=\s*(.+)/)
                            key = $1
                            val = $2

                            case key
                                when "loglevel"
                                    @loglevel = val
                                when "logfile"
                                    @logfile = val
                                when "pidfile"
                                    @pidfile = val
                                when "templatedir"
                                    @templatedir = val
                                when "spooldir"
                                    @spooldir = val
                                when "user"
                                    @user = val
                                when "group"
                                    @group = val
                                when "plugin"
                                    @plugins << val
                                when /^plugin\.(.+?)\.(.+)$/
                                    @pluginconfig[$1] = {} unless @pluginconfig[$1]
                                    @pluginconfig[$1][$2] = val
                                else
                                    raise("Unknown config parameter #{key}")
                            end
                        end
                    end
                end
            end

            Angelia::Util.config = self

            loadplugins if startplugins
        end

        # Gets the config a given plugin without passing the main
        # config or config from other plugins into it.
        def pluginconf(plugin)
            @pluginconfig[plugin]
        end

        # Load all configured plugins and call their register method to initialize them
        def loadplugins
            @plugins.each do |p|
                Angelia::Util.debug("loading plugin angelia/plugin/#{p.downcase}.rb and registering Angelia::Plugin::#{p}")

                Kernel.load("angelia/plugin/#{p.downcase}.rb")
                eval("Angelia::Plugin::#{p}.register")
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
