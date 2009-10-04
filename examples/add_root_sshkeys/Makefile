#
# Author:Joe Block <jpb@ApesSeekingKnowledge.net>
# License: BSD
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
