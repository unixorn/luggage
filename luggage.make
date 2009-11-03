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

STAMP:=`date +%Y%m%d`
YY:=`date +%Y`
MM:=`date +%m`
DD:=`date +%d`

# mai plist haz a flavor
PLIST_FLAVOR=plist
PACKAGE_PLIST=.package.plist

PACKAGE_TARGET_OS=10.4
PLIST_TEMPLATE=prototype.plist
TITLE=CHANGE_ME
REVERSE_DOMAIN=com.replaceme
PACKAGE_ID=${REVERSE_DOMAIN}.${TITLE}

# Set PACKAGE_VERSION in your Makefile if you don't want version set to
# today's date
PACKAGE_VERSION=${STAMP}

# Set PACKAGE_NAME in your Makefile if you don't want it to be TITLE-PACKAGEVERSION.
PACKAGE_NAME=${TITLE}-${PACKAGE_VERSION}
PACKAGE_FILE=${PACKAGE_NAME}.pkg
DMG_NAME=${PACKAGE_NAME}.dmg

# Only use Apple tools for file manipulation, or deal with a world of pain
# when your resource forks get munched.  This is particularly important on
# 10.6 since it stores compressed binaries in the resource fork.
TAR=/usr/bin/tar
CP=/bin/cp
INSTALL=/usr/bin/install

PACKAGEMAKER=/Developer/usr/bin/packagemaker

# Must be on an HFS+ filesystem. Yes, I know some network servers will do
# their best to preserve the resource forks, but it isn't worth the aggravation
# to fight with them.
LUGGAGE_TMP=/tmp/the_luggage
SCRATCH_D=${LUGGAGE_TMP}/${PACKAGE_NAME}

SCRIPT_D=${SCRATCH_D}/scripts
WORK_D=${SCRATCH_D}/root
PAYLOAD_D=${SCRATCH_D}/payload

# packagemaker parameters
#
# packagemaker will helpfully apply the permissions it finds on the system
# if one of the files in the payload exists on the disk, rather than the ones
# you've carefully set up in the package root, so I turn that crap off with
# --no-recommend. You can disable this by overriding PM_EXTRA_ARGS in your
# package's Makefile.

PM_EXTRA_ARGS=--verbose --no-recommend

# Override if you want to require a restart after installing your package.
PM_RESTART=None
PAYLOAD=

# Set .PHONY declarations so things don't break if someone has files in
# their workdir with the same names as our special stanzas

.PHONY: clean
.PHONY: debug
.PHONY: dmg
.PHONY: grind_package
.PHONY: local_pkg
.PHONY: package_root
.PHONY: payload_d
.PHONY: pkg
.PHONY: scratchdir
.PHONY: superclean

# Convenience variables
USER_TEMPLATE=${WORK_D}/System/Library/User\ Template
USER_TEMPLATE_PREFERENCES=${USER_TEMPLATE}/English.lproj/Library/Preferences
USER_TEMPLATE_PICTURES=${USER_TEMPLATE}/English.lproj/Pictures

# target stanzas

help:
	@-echo
	@-echo "make clean - clean up work files."
	@-echo "make dmg - roll a pkg, then stuff it into a dmg file."
	@-echo "make pkg - roll a pkg."
	@-echo

# set up some work directories

payload_d:
	@sudo mkdir -p ${PAYLOAD_D}

package_root:
	@sudo mkdir -p ${WORK_D}

scriptdir:
	@sudo mkdir -p ${SCRIPT_D}

scratchdir:
	@sudo mkdir -p ${SCRATCH_D}

# user targets

clean:
	@sudo rm -fr ${SCRATCH_D} .luggage.pkg.plist ${PACKAGE_PLIST}

superclean:
	@sudo rm -fr ${LUGGAGE_TMP}

dmg: scratchdir compile_package
	@echo "Wrapping ${PACKAGE_NAME}..."
	@sudo hdiutil create -volname ${PACKAGE_NAME} \
		-srcfolder ${PAYLOAD_D} \
		-uid 99 -gid 99 \
		-ov \
		${DMG_NAME}

modify_packageroot:
	@echo "If you need to override permissions or ownerships, override modify_packageroot in your Makefile"

prep_pkg:
	@make clean
	@make payload
	@make modify_packageroot
	@make compile_package

pkg: prep_pkg
	@make local_pkg

pkgls: prep_pkg
	@echo
	@echo
	lsbom -p fmUG ${PAYLOAD_D}/${PACKAGE_FILE}/Contents/Archive.bom

#
payload: payload_d package_root scratchdir scriptdir
	make ${PAYLOAD}
	@-echo

compile_package: payload .luggage.pkg.plist
	@-sudo rm -fr ${PAYLOAD_D}/${PACKAGE_FILE}
	@echo "Creating ${PAYLOAD_D}/${PACKAGE_FILE}"
	sudo ${PACKAGEMAKER} --root ${WORK_D} \
		--id ${PACKAGE_ID} \
		--target ${PACKAGE_TARGET_OS} \
		--title ${TITLE} \
		--info ${SCRATCH_D}/luggage.pkg.plist \
		--scripts ${SCRIPT_D} \
		--version ${PACKAGE_VERSION} \
		${PM_EXTRA_ARGS} --out ${PAYLOAD_D}/${PACKAGE_FILE}

${PACKAGE_PLIST}: /usr/local/share/luggage/prototype.plist
# override this stanza if you have a different plist you want to use as
# a custom local template.
	@cat /usr/local/share/luggage/prototype.plist > ${PACKAGE_PLIST}

.luggage.pkg.plist: ${PACKAGE_PLIST}
	@cat ${PACKAGE_PLIST} | \
		sed "s/{DD}/${DD}/g" | \
		sed "s/{MM}/${MM}/g" | \
		sed "s/{YY}/${YY}/g" | \
		sed "s/{PACKAGE_ID}/${PACKAGE_ID}/g" | \
		sed "s/{PACKAGE_VERSION}/${PACKAGE_VERSION}/g" | \
		sed "s/{PM_RESTART}/${PM_RESTART}/g" | \
	        sed "s/{PLIST_FLAVOR}/${PLIST_FLAVOR}/g" \
		> .luggage.pkg.plist
	@sudo ${CP} .luggage.pkg.plist ${SCRATCH_D}/luggage.pkg.plist
	@rm .luggage.pkg.plist ${PACKAGE_PLIST}

local_pkg:
	@${CP} -R ${PAYLOAD_D}/${PACKAGE_FILE} .

# Target directory rules

l_root: package_root
	@sudo mkdir -p ${WORK_D}
	@sudo chmod 755 ${WORK_D}
	@sudo chown root:admin ${WORK_D}

l_etc: l_root
	@sudo mkdir -p ${WORK_D}/etc
	@sudo chown -R root:wheel ${WORK_D}/etc
	@sudo chmod -R 755 ${WORK_D}/etc

l_etc_hooks: l_etc
	@sudo mkdir -p ${WORK_D}/etc/hooks
	@sudo chown -R root:wheel ${WORK_D}/etc/hooks
	@sudo chmod -R 755 ${WORK_D}/etc/hooks

l_usr: l_root
	@sudo mkdir -p ${WORK_D}/usr
	@sudo chown -R root:wheel ${WORK_D}/usr
	@sudo chmod -R 755 ${WORK_D}/usr

l_usr_bin: l_usr
	@sudo mkdir -p ${WORK_D}/usr/bin
	@sudo chown -R root:wheel ${WORK_D}/usr/bin
	@sudo chmod -R 755 ${WORK_D}/usr/bin

l_usr_lib: l_usr
	@sudo mkdir -p ${WORK_D}/usr/lib
	@sudo chown -R root:wheel ${WORK_D}/usr/lib
	@sudo chmod -R 755 ${WORK_D}/usr/lib

l_usr_local: l_usr
	@sudo mkdir -p ${WORK_D}/usr/local
	@sudo chown -R root:wheel ${WORK_D}/usr/local
	@sudo chmod -R 755 ${WORK_D}/usr/local

l_usr_local_bin: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/bin
	@sudo chown -R root:wheel ${WORK_D}/usr/local/bin
	@sudo chmod -R 755 ${WORK_D}/usr/local/bin

l_usr_local_lib: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/lib
	@sudo chown -R root:wheel ${WORK_D}/usr/local/lib
	@sudo chmod -R 755 ${WORK_D}/usr/local/lib

l_usr_local_man: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/man
	@sudo chown -R root:wheel ${WORK_D}/usr/local/man
	@sudo chmod -R 755 ${WORK_D}/usr/local/man

l_usr_local_sbin: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/sbin
	@sudo chown -R root:wheel ${WORK_D}/usr/local/sbin
	@sudo chmod -R 755 ${WORK_D}/usr/local/sbin

l_usr_local_share: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/share
	@sudo chown -R root:wheel ${WORK_D}/usr/local/share
	@sudo chmod -R 755 ${WORK_D}/usr/local/share

l_usr_sbin: l_usr
	@sudo mkdir -p ${WORK_D}/usr/sbin
	@sudo chown -R root:wheel ${WORK_D}/usr/sbin
	@sudo chmod -R 755 ${WORK_D}/usr/sbin

l_usr_share: l_usr
	@sudo mkdir -p ${WORK_D}/usr/share
	@sudo chown -R root:wheel ${WORK_D}/usr/share
	@sudo chmod -R 755 ${WORK_D}/usr/share

l_var: l_root
	@sudo mkdir -p ${WORK_D}/var
	@sudo chown -R root:wheel ${WORK_D}/var
	@sudo chmod -R 755 ${WORK_D}/var

l_var_db: l_var
	@sudo mkdir -p ${WORK_D}/var/db
	@sudo chown -R root:wheel ${WORK_D}/var/db
	@sudo chmod -R 755 ${WORK_D}/var/db

l_var_root: l_var
	@sudo mkdir -p ${WORK_D}/var/root
	@sudo chown -R root:wheel ${WORK_D}/var/root
	@sudo chmod -R 750 ${WORK_D}/var/root

l_Applications: l_root
	@sudo mkdir -p ${WORK_D}/Applications
	@sudo chown root:admin ${WORK_D}/Applications
	@sudo chmod 775 ${WORK_D}/Applications

l_Applications_Utilities: l_root
	@sudo mkdir -p ${WORK_D}/Applications/Utilities
	@sudo chown root:admin ${WORK_D}/Applications/Utilities
	@sudo chmod 755 ${WORK_D}/Applications/Utilities

l_Library: l_root
	@sudo mkdir -p ${WORK_D}/Library
	@sudo chown root:admin ${WORK_D}/Library
	@sudo chmod 1775 ${WORK_D}/Library

l_Library_Desktop_Pictures: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Desktop\ Pictures
	@sudo chown root:admin ${WORK_D}/Library/Desktop\ Pictures
	@sudo chmod 775 ${WORK_D}/Library/Desktop\ Pictures

l_Library_LaunchAgents: l_Library
	@sudo mkdir -p ${WORK_D}/Library/LaunchAgents
	@sudo chown root:wheel ${WORK_D}/Library/LaunchAgents
	@sudo chmod 755 ${WORK_D}/Library/LaunchAgents

l_Library_LaunchDaemons: l_Library
	@sudo mkdir -p ${WORK_D}/Library/LaunchDaemons
	@sudo chown root:wheel ${WORK_D}/Library/LaunchDaemons
	@sudo chmod 755 ${WORK_D}/Library/LaunchDaemons

l_Library_Preferences: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Preferences
	@sudo chown root:admin ${WORK_D}/Library/Preferences
	@sudo chmod 775 ${WORK_D}/Library/Preferences

l_Library_Printers: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Printers
	@sudo chown root:admin ${WORK_D}/Library/Printers
	@sudo chmod 775 ${WORK_D}/Library/Printers

l_Library_Printers_PPDs: l_Library_Printers
	@sudo mkdir -p ${WORK_D}/Library/Printers/PPDs/Contents/Resources
	@sudo chown root:admin ${WORK_D}/Library/Printers/PPDs
	@sudo chmod 775 ${WORK_D}/Library/Printers/PPDs

l_PPDs: l_Library_Printers_PPDs

l_Library_Receipts: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Receipts
	@sudo chown root:admin ${WORK_D}/Library/Receipts
	@sudo chmod 775 ${WORK_D}/Library/Receipts

l_Library_User_Pictures: l_Library
	@sudo mkdir -p ${WORK_D}/Library/User\ Pictures
	@sudo chown root:admin ${WORK_D}/Library/User\ Pictures
	@sudo chmod 775 ${WORK_D}/Library/User\ Pictures

l_Library_CorpSupport: l_Library
	@sudo mkdir -p ${WORK_D}/Library/CorpSupport
	@sudo chown root:admin ${WORK_D}/Library/CorpSupport
	@sudo chmod 775 ${WORK_D}/Library/CorpSupport

l_Library_Python: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Python
	@sudo chown root:admin ${WORK_D}/Library/Python
	@sudo chmod 775 ${WORK_D}/Library/Python

l_Library_Python_26: l_Library_Python
	@sudo mkdir -p ${WORK_D}/Library/Python/2.6
	@sudo chown root:admin ${WORK_D}/Library/Python/2.6
	@sudo chmod 775 ${WORK_D}/Library/Python/2.6

l_Library_Python_26_site_packages: l_Library_Python_26
	@sudo mkdir -p ${WORK_D}/Library/Python/2.6/site-packages
	@sudo chown root:admin ${WORK_D}/Library/Python/2.6/site-packages
	@sudo chmod 775 ${WORK_D}/Library/Python/2.6/site-packages

l_Library_Ruby: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Ruby
	@sudo chown root:admin ${WORK_D}/Library/Ruby
	@sudo chmod 775 ${WORK_D}/Library/Ruby

l_Library_Ruby_Site: l_Library_Ruby
	@sudo mkdir -p ${WORK_D}/Library/Ruby/Site
	@sudo chown root:admin ${WORK_D}/Library/Ruby/Site
	@sudo chmod 775 ${WORK_D}/Library/Ruby/Site

l_Library_Ruby_Site_1_8: l_Library_Ruby_Site
	@sudo mkdir -p ${WORK_D}/Library/Ruby/Site/1.8
	@sudo chown root:admin ${WORK_D}/Library/Ruby/Site/1.8
	@sudo chmod 775 ${WORK_D}/Library/Ruby/Site/1.8

l_System: l_root
	@sudo mkdir -p ${WORK_D}/System
	@sudo chown -R root:wheel ${WORK_D}/System
	@sudo chmod -R 755 ${WORK_D}/System

l_System_Library: l_System
	@sudo mkdir -p ${WORK_D}/System/Library
	@sudo chown -R root:wheel ${WORK_D}/System/Library
	@sudo chmod -R 755 ${WORK_D}/System/Library

l_System_Library_User_Template: l_System_Library
	@sudo mkdir -p ${WORK_D}/System/Library/User\ Template/English.lproj
	@sudo chown -R root:wheel ${WORK_D}/System/Library/User\ Template/English.lproj
	@sudo chmod 700 ${WORK_D}/System/Library/User\ Template
	@sudo chmod -R 755 ${WORK_D}/System/Library/User\ Template/English.lproj

l_System_Library_User_Template_Library: l_System_Library_User_Template
	@sudo mkdir -p ${WORK_D}/System/Library/User\ Template/English.lproj/Library
	@sudo chown root:wheel ${WORK_D}/System/Library/User\ Template/English.lproj/Library
	@sudo chmod 700 ${WORK_D}/System/Library/User\ Template/English.lproj/Library

l_System_Library_User_Template_Pictures: l_System_Library_User_Template
	@sudo mkdir -p ${WORK_D}/System/Library/User\ Template/English.lproj/Pictures
	@sudo chown root:wheel ${WORK_D}/System/Library/User\ Template/English.lproj/Pictures
	@sudo chmod 700 ${WORK_D}/System/Library/User\ Template/English.lproj/Pictures

l_System_Library_User_Template_Preferences: l_System_Library_User_Template_Library
	@sudo mkdir -p ${USER_TEMPLATE_PREFERENCES}
	@sudo chown root:wheel ${USER_TEMPLATE_PREFERENCES}
	@sudo chmod -R 700 ${USER_TEMPLATE_PREFERENCES}

# file packaging rules

pack-site-python-%: % l_Library_Python_26_site_packages
	@sudo ${INSTALL} -m 644 -g admin -o root $< ${WORK_D}/Library/Python/2.6/site-packages

pack-siteruby-%: % l_Library_Ruby_Site_1_8
	@sudo ${INSTALL} -m 644 -g wheel -o root $< ${WORK_D}/Library/Ruby/Site/1.8

pack-Library-LaunchAgents-%: % l_Library_LaunchAgents
	@sudo ${INSTALL} -m 644 -g wheel -o root $< ${WORK_D}/Library/LaunchAgents

pack-Library-LaunchDaemons-%: % l_Library_LaunchDaemons
	@sudo ${INSTALL} -m 644 -g wheel -o root $< ${WORK_D}/Library/LaunchDaemons

pack-Library-Preferences-%: % l_Library_Preferences
	@sudo ${INSTALL} -m 644 -g admin -o root $< ${WORK_D}/Library/Preferences

pack-ppd-%: % l_PPDs
	@sudo ${INSTALL} -m 664 -g admin -o root $< ${WORK_D}/Library/Printers/PPDs/Contents/Resources

pack-script-%: % scriptdir
	@sudo ${INSTALL} -m 755 $< ${SCRIPT_D}

pack-user-template-plist-%: % l_System_Library_User_Template_Preferences
	@sudo ${INSTALL} -m 644 $< ${USER_TEMPLATE_PREFERENCES}

pack-user-picture-%: % l_Library_Desktop_Pictures
	@sudo ${INSTALL} -m 644 $< ${WORK_D}/Library/Desktop\ Pictures

# posixy file stanzas

pack-etc-%: % l_etc
	@sudo ${INSTALL} -m 644 -g wheel -o root $< ${WORK_D}/etc

pack-usr-bin-%: % l_usr_bin
	@sudo ${INSTALL} -m 755 -g wheel -o root $< ${WORK_D}/usr/bin

pack-usr-sbin-%: % l_usr_sbin
	@sudo ${INSTALL} -m 755 -g wheel -o root $< ${WORK_D}/usr/sbin

pack-usr-local-bin-%: % l_usr_local_bin
	@sudo ${INSTALL} -m 755 -g wheel -o root $< ${WORK_D}/usr/local/bin

pack-usr-local-sbin-%: % l_usr_local_sbin
	@sudo ${INSTALL} -m 755 -g wheel -o root $< ${WORK_D}/usr/local/sbin

pack-hookscript-%: % l_etc_hooks
	@sudo ${INSTALL} -m 755 $< ${WORK_D}/etc/hooks

# Applications and Utilities
#
# We use ${TAR} because it respects resource forks. This is still
# critical - just when I thought I'd seen the last of the damn things, Apple
# decided to stash compressed binaries in them in 10.6.

unbz2-applications-%: %.tar.bz2 l_Applications
	@sudo ${TAR} xjf $< -C ${WORK_D}/Applications
	@sudo chown -R root:admin ${WORK_D}/Applications/$(shell echo $< | sed s/\.tar\.bz2//g)

unbz2-utilities-%: %.tar.bz2 l_Applications_Utilities
	@sudo ${TAR} xjf $< -C ${WORK_D}/Applications/Utilities
	@sudo chown -R root:admin ${WORK_D}/Applications/Utilities/$(shell echo $< | sed s/\.tar\.bz2//g)

ungz-applications-%: %.tar.gz l_Applications
	@sudo ${TAR} xzf $< -C ${WORK_D}/Applications
	@sudo chown -R root:admin ${WORK_D}/Applications/$(shell echo $< | sed s/\.tar\.gz//g)

ungz-utilities-%: %.tar.gz l_Applications_Utilities
	@sudo ${TAR} xzf $< -C ${WORK_D}/Applications/Utilities
	@sudo chown -R root:admin ${WORK_D}/Applications/Utilities/$(shell echo $< | sed s/\.tar\.gz//g)
