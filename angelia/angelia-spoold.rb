#!/usr/bin/ruby

require 'angelia'
require 'getoptlong'
require 'etc'

opts = GetoptLong.new(
    [ '--config', '-c', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--foreground', '-f', GetoptLong::NO_ARGUMENT ]
)

want_daemon = true
conffile = "/etc/angelia/angelia.cfg"

opts.each do |opt, arg|
    case opt
        when '--config'
            conffile = arg
        when '--foreground'
            want_daemon = false
    end
end


# Goes into the background, chdir's to /tmp, and redirect all input/output to null
# Beginning Ruby p. 489-490
def daemonize
    fork do
        Process.setsid
        exit if fork
        #Dir.chdir('/tmp')
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen('/dev/null', 'a')

        trap("TERM") {
            exit
        }

        yield
    end
end

# Do this outside of daemonize, in case there are errors
Angelia::Config.new(conffile)
s = Angelia::Spool.new

if Angelia::Util.config.group
    Process::GID.change_privilege(Etc.getgrnam(Angelia::Util.config.group)["gid"])
end

if Angelia::Util.config.user
    Process::UID.change_privilege(Etc.getpwnam(Angelia::Util.config.user)["uid"])
end

if want_daemon
    daemonize do
        File.open(Angelia::Util.config.pidfile, 'w') do |f|
            f.write(Process.pid.to_s)
        end
        s.run
    end
else
     s.run
end

# vi:tabstop=4:expandtab:ai
