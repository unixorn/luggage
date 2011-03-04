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
#  Angelia Package Creation:

include /usr/local/share/luggage/luggage.make

TITLE=Angelia_Installer
REVERSE_DOMAIN=com.huronhs
PAYLOAD=\
		pack-angelia-etc \
		pack-angelia-binaries \
		pack-angelia-lib \
		pack-angelia-spool \
		pack-angelia-log \
		pack-angelia-launchd


pack-angelia-launchd: l_Library_LaunchDaemons
	@sudo ${CP} net.devco.angelia.plist ${WORK_D}/Library/LaunchDaemons
	@sudo chmod -R 644 ${WORK_D}/Library/LaunchDaemons
	
pack-angelia-binaries: l_usr_sbin
	@sudo ${CP} ./angelia-send.rb ${WORK_D}/usr/sbin/angelia-send
	@sudo ${CP} ./angelia-spoold.rb ${WORK_D}/usr/sbin/angelia-spoold
	@sudo ${CP} ./angelia-nagios-send.rb ${WORK_D}/usr/sbin/angelia-nagios-send
	@sudo chmod -R 755 ${WORK_D}/usr/sbin
	
pack-angelia-lib: l_Library_Ruby_Site_1_8
	@sudo ${CP} -R ./angelia ${WORK_D}/Library/Ruby/Site/1.8
	@sudo ${CP} ./angelia.rb ${WORK_D}/Library/Ruby/Site/1.8
	@sudo chmod -R 755 ${WORK_D}/Library/Ruby/Site/1.8
	
pack-angelia-etc: l_etc_angelia
	@sudo ${CP} -R ./templates ${WORK_D}/etc/angelia
	@sudo ${CP} ./angelia.cfg ${WORK_D}/etc/angelia
	@sudo ${CP} ./COPYING ${WORK_D}/etc/angelia
	@sudo ${CP} ./README.markdown ${WORK_D}/etc/angelia
	@sudo chmod -R 755 ${WORK_D}/etc/angelia
	
pack-angelia-log: l_var_log_angelia
	@sudo touch .create
pack-angelia-spool: l_var_spool_angelia
	@sudo touch .create