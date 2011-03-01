#
#   Copyright 2009 Joe Block <jpb@ApesSeekingKnowledge.net>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
include /usr/local/share/luggage/luggage.make

TITLE=enable_loginhooks
REVERSE_DOMAIN=com.example.corp
PAYLOAD=\
	unbz2-utilities-iHook.app \
	pack-hook-background.jpg \
	pack-hookscript-LO999_DestroyKerberosTicket.hook \
	pack-hookscript-login.hook \
	pack-hookscript-logout.hook \
	pack-hookscript-run_loginscripts.rb \
	pack-hookscript-run_logoutscripts.rb \
	pack-hookscript-hookutils.rb \
	pack-script-postflight

TARBALL_LOCATION="http://location/of/tarball"

# stick a background image into /etc/hooks to use with iHook.
pack-hook-background.jpg: hook_background.jpg l_etc_hooks
	@sudo ${INSTALL} -m 644 hook_background.jpg ${WORK_D}/etc/hooks/hook_background.jpg


# The Luggage's rules presume that an app, foo.app, will be packed in a
# tarball named foo.app.tar, then compressed. The downside to that is that if
# you try to recreate a specific version of the package, you have to remember
# which version of the app was in the tarball.
#
# To make that easier to cope with, I keep master copies with the datestamp
# embedded in the tarball name, then just download it to the working directory.
#
# Note that I'm making the tarball depend on Makefile - that way when I edit
# Makefile to put in a new tarball url, make will automatically replace the
# current generically named tarball with a current copy from my local repo

iHook.app.tar.bz2: Makefile
	curl ${TARBALL_LOCATION} -o iHook.app.tar.bz2
