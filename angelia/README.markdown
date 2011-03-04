This is a tool to facilitate the development of nagios notification
methods using many different protocols and delivery systems while
using a single simple script that can deliver all messages.

Messages have recipients in the form:

        protocol://recipient

and each protocol gets handled by a different plugin.

At present there are just two plugins that serve as a introduction to the
plugin system, see [Angelia::Plugin::Xmpp](https://github.com/ripienaar/angelia/blob/master/angelia/plugin/xmpp.rb) and [Angelia::Plugin::Clickatell](https://github.com/ripienaar/angelia/blob/master/angelia/plugin/clickatell.rb).

When called from inside nagios a script - _angelia-nagios-send_ - should be used
it will assist in building up the message bodies by means of templates and the
state provided by nagios, each protocol can have its own templates for host and
service notifies, these are in files:

        templates/protocol-host.erb
        templates/protocol-service.erb

See the [provided templates](https://github.com/ripienaar/angelia/tree/master/templates/) for samples

And you can use any of the _NAGIOS\_\*_ variables that Nagios sets in the environment.

The nagios commands to send notifications via this tools are:

        define command{
                command_name host-notify-by-angelia
                command_line /usr/sbin/angelia-nagios-send -c /etc/angelia/angelia.cfg --host-notify -r $CONTACTEMAIL$
        }

        define command{
                command_name notify-by-angelia
                command_line /usr/sbin/angelia-nagios-send -c /etc/angelia/angelia.cfg --service-notify -r $CONTACTEMAIL$
        }

This will set all the nagios environment variables and the angelia notifier will use these with the templates mentioned earlier.

Normal messages can be send using angelia-send fro the command line or other monitoring systems, in this case you need to provide
your own message body.

Sample calls to put messages on the spool are:

        $ angelia-nagios-send -c /etc/angelia/angelia.cfg --service-notify -r xmpp://you@jabber.com
        $ angelia-send -c /etc/angelia/angelia.cfg -r xmpp://you@jabber.com -m 'my message'

Included in the source are init scripts, daemon to run and poll the spool and also a RPM spec file to build it.

This code is released under the terms of the Apache version 2 license.

Contact R.I.Pienaar <rip@devco.net> / [www.devco.net](http://www.devco.net/) / [@ripienaar](http://twitter.com/ripienaar)

