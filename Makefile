#
# Joe Block <jpb@ApesSeekingKnowledge.net
#
# Sample package

include /usr/local/share/luggage.make

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
