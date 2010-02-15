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

include luggage.make

TITLE=luggage
REVERSE_DOMAIN=net.apesseekingknowledge
PAYLOAD=pack-luggage.make pack-prototype.plist

help:
	@-echo
	@-echo "make bootstrap_files to copy luggage's files to /usr/local/share/luggage"
	@-echo
	@-echo "Once you've made bootstrap_files, you can 'make pkg' or 'make dmg' to make"
	@-echo "a package that will install luggage on a machine."

l_usr_local_share_luggage: l_usr_local_share
	@sudo mkdir -p ${WORK_D}/usr/local/share/luggage
	@sudo chown root:wheel ${WORK_D}/usr/local/share/luggage
	@sudo chmod 755 ${WORK_D}/usr/local/share/luggage

pack-prototype.plist: l_usr_local_share_luggage
	@sudo ${INSTALL} -m 644 -o root -g wheel prototype.plist ${WORK_D}/usr/local/share/luggage/prototype.plist

pack-luggage.make: l_usr_local_share_luggage
	@sudo ${INSTALL} -m 644 -o root -g wheel luggage.make ${WORK_D}/usr/local/share/luggage/luggage.make

# copy the luggage files into place on the local machine so we can build a pkg.
bootstrap_files: bootstrap_directory
	@sudo ${INSTALL} -m 644 -o root -g wheel luggage.make /usr/local/share/luggage/luggage.make
	@sudo ${INSTALL} -m 644 -o root -g wheel prototype.plist /usr/local/share/luggage/prototype.plist

bootstrap_directory:
	@sudo mkdir -p /usr/local/share/luggage
