#
# Author:Joe Block <jpb@ApesSeekingKnowledge.net>
# License: BSD
# 
# Example of packaging a gui application

include /usr/local/share/luggage/luggage.make

TITLE=install_foo_app
REVERSE_DOMAIN=com.example.corp
PAYLOAD=unbz2-applications-foo.app

# Create a .tar.bz2 or .tar.gz of the application you want to install, and
# then use unXX-applications-foo.app to install into /Applications, or
# unXX-utilities-foo.app to install into Utilities (replace XX with bz2 or
# gz as appropriate for your tarball).
#
# Make sure you use Apple's tar to create the tarball so resource forks and
# metadata are preserved.
