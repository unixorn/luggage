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
# Sample package that packages luggage.make and prototype.plist

include /usr/local/share/luggage/luggage.make

TITLE=luggage
REVERSE_DOMAIN=net.apesseekingknowledge
PAYLOAD=pack-luggage.make

l_usr_local_share_luggage: l_usr_local_share
	@sudo mkdir -p ${WORK_D}/usr/local/share/luggage
	@sudo chown root:wheel ${WORK_D}/usr/local/share/luggage
	@sudo chmod 755 ${WORK_D}/usr/local/share/luggage

pack-prototype.plist: l_usr_local_share_luggage
	@sudo ${INSTALL} -m 644 -o root -g wheel prototype.plist ${WORK_D}/usr/local/share/luggage/luggage.make

pack-luggage.make: l_usr_local_share_luggage
	 @sudo ${INSTALL} -m 644 -o root -g wheel luggage.make ${WORK_D}/usr/local/share/luggage/luggage.make
