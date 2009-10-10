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
# Example showing adding new target directories

include /usr/local/share/luggage/luggage.make

TITLE=add_root_sshkeys
REVERSE_DOMAIN=com.example.corp
PAYLOAD=pack-var-root-authorized_keys

prep-var-root-ssh: l_var_root
	@sudo mkdir -p ${WORK_D}/var/root/.ssh
	@sudo chown root:wheel ${WORK_D}/var/root/.ssh
	@sudo chmod 700 ${WORK_D}/var/root/.ssh

pack-var-root-authorized_keys: prep-var-root-ssh authorized_keys
	@sudo ${INSTALL} -m 600 -o root -g wheel authorized_keys ${WORK_D}/var/root/.ssh/authorized_keys
