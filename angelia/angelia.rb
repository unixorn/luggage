require 'yaml'

# This is a tool to facilite the development of nagios notification
# methods using many different protocols and delivery systems while
# using a single simple script that can deliver all messages.
#
# Messages have recipients in the form:
#
#    protocol://recipient
#
# and each protocol gets handled by a different plugin.
#
# At present there are just two plugins that serve as a introduction to the
# plugin system, see [Angelia::Plugin::Twitter] and [Angelia::Plugin::Xmpp].
#
# When called from inside nagios a script - angelia-nagios-send - should be used
# it will assist in building up the message bodies by means of templates and the
# state provided by nagios, each protocol can have its own templates for host and
# service notifies, these are in files:
#
#    templates/protocol-host.erb
#    templates/protocol-service.erb
#
# And you can use any of the NAGIOS_* variables that Nagios sets in the environment.
#
# Normal messages can be send using angelia-send, in this case you need to provide
# your own message body.
#
# Sample calls to put messages on the spool are:
#
#    angelia-nagios-send -c /etc/angelia/angelia.cfg --service-notify -r xmpp://you@jabber.com
#    angelia-send -c /etc/angelia/angelia.cfg -r xmpp://you@jabber.com -m 'my message'
#
# Included in the tarball are init scripts, daemon to run and pol the spool etc.
#
# Contact rip <at> devco.net with any questions.
module Angelia
    autoload :Util, "angelia/util.rb"
    autoload :Config, "angelia/config.rb"
    autoload :Spool, "angelia/spool.rb"
    autoload :Message, "angelia/message.rb"
    autoload :Recipient, "angelia/recipient.rb"
end

# vi:tabstop=4:expandtab:ai
