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

export STAMP:=$(shell date +%Y%m%d)
export YY:=$(shell date +%Y)
export MM:=$(shell date +%m)
export DD:=$(shell date +%d)
export BUILD_DATE=$(shell date -u "+%Y-%m-%dT%H:%M:%SZ")

# mai plist haz a flavor
PLIST_FLAVOR=plist
PACKAGE_PLIST=.package.plist

PACKAGE_TARGET_OS=10.4
PLIST_TEMPLATE=prototype.plist
PLIST_PATH=/usr/local/share/luggage/prototype.plist
TITLE=CHANGE_ME
REVERSE_DOMAIN=com.replaceme
PACKAGE_ID=${REVERSE_DOMAIN}.${TITLE}

# Set PACKAGE_VERSION in your Makefile if you don't want version set to
# today's date
PACKAGE_VERSION=${STAMP}
PACKAGE_MAJOR_VERSION=${YY}
PACKAGE_MINOR_VERSION=${MM}${DD}

# Set PACKAGE_NAME in your Makefile if you don't want it to be TITLE-PACKAGEVERSION.
PACKAGE_NAME=${TITLE}-${PACKAGE_VERSION}
PACKAGE_FILE=${PACKAGE_NAME}.pkg
DMG_NAME=${PACKAGE_NAME}.dmg
ZIP_NAME=${PACKAGE_FILE}.zip

# Only use Apple tools for file manipulation, or deal with a world of pain
# when your resource forks get munched.  This is particularly important on
# 10.6 since it stores compressed binaries in the resource fork.
TAR=/usr/bin/tar
CP=/bin/cp
INSTALL=/usr/bin/install
DITTO=/usr/bin/ditto

NCPUS:=$(shell expr $$(sysctl -n hw.ncpu) + 2)

PKGBUILD=/usr/bin/pkgbuild

# Optionally, build packages with packagemaker, set USE_PKGBUILD=0
PACKAGEMAKER=/usr/local/bin/packagemaker

# Use productbuild to create flat distribution bundles - pkg-dist
PRODUCTBUILD=/usr/bin/productbuild
PKG_DIST=${TITLE}_dist-${PACKAGE_VERSION}.pkg

# Must be on an HFS+ filesystem. Yes, I know some network servers will do
# their best to preserve the resource forks, but it isn't worth the aggravation
# to fight with them.
LUGGAGE_TMP=/tmp/the_luggage
OUTPUT_D=.
SCRATCH_D=${LUGGAGE_TMP}/${PACKAGE_NAME}

SCRIPT_D=${SCRATCH_D}/scripts
RESOURCE_D=${SCRATCH_D}/resources
EN_LPROJ_D=${RESOURCE_D}/en.lproj
WORK_D=${SCRATCH_D}/root
PAYLOAD_D=${SCRATCH_D}/payload
BUILD_D=${SCRATCH_D}/build

# packagemaker parameters
#
# packagemaker will helpfully apply the permissions it finds on the system
# if one of the files in the payload exists on the disk, rather than the ones
# you've carefully set up in the package root, so I turn that crap off with
# --no-recommend. You can disable this by overriding PM_EXTRA_ARGS in your
# package's Makefile.

PM_EXTRA_ARGS=--verbose --no-recommend --no-relocate
PM_FILTER=--filter "/CVS$$" --filter "/\.svn$$" --filter "/\.cvsignore$$" --filter "/\.cvspass$$" --filter "/(\._)?\.DS_Store$$" --filter "/\.git$$" --filter "/\.gitignore$$"

# package build parameters
#
# just like packagemaker, pkgbuild munges permissions unless you tell it not to.

PB_EXTRA_ARGS=--ownership preserve --quiet


# pkgbuild can build payload free packages, but you have to say if you want one.

ifeq (${NO_PAYLOAD}, 1)
PB_EXTRA_ARGS+=" --nopayload"
endif

# Set to false if you want your package to install to volumes other than the boot volume
ROOT_ONLY=true
# Override if you want to require a restart after installing your package.
PM_RESTART=None
PAYLOAD=

# hdiutil parameters
#
# hdiutil will create a compressed disk image with the UDZO and UDBZ formats,
# or a bland, uncompressed, read-only image with UDRO. Wouldn't you rather
# trade a little processing time for some disk savings now that you can make
# packages and images with reckless abandon?
#
# The UDZO format is selected as the default here for compatibility, but you
# can override it to achieve higher compression. If you want to switch away
# from UDZO, it is probably best to override DMG_FORMAT in your makefile.
#
# Format notes:
# The UDRO format is an uncompressed, read-only disk image that is compatible
# with Mac OS X 10.0 and later.
# The UDZO format is gzip-based, defaults to gzip level 1, and is compatible
# with Mac OS X 10.2 and later.
# The UDBZ format is bzip2-based and is compatible with Mac OS X 10.4 and later.

DMG_FORMAT_CODE=UDZO
ZLIB_LEVEL=9
DMG_FORMAT_OPTION=-imagekey zlib-level=${ZLIB_LEVEL}
DMG_FORMAT=${DMG_FORMAT_CODE} ${DMG_FORMAT_OPTION}

# Set .PHONY declarations so things don't break if someone has files in
# their workdir with the same names as our special stanzas

.PHONY: clean
.PHONY: debug
.PHONY: dmg
.PHONY: grind_package
.PHONY: package_root
.PHONY: payload_d
.PHONY: pkg
.PHONY: scratchdir
.PHONY: superclean

# Convenience variables
USER_TEMPLATE=${WORK_D}/System/Library/User\ Template
USER_TEMPLATE_PREFERENCES=${USER_TEMPLATE}/English.lproj/Library/Preferences
USER_TEMPLATE_PICTURES=${USER_TEMPLATE}/English.lproj/Pictures


LUGGAGE_LOCAL:=$(dir $(word $(words $(MAKEFILE_LIST)), \
	$(MAKEFILE_LIST)))/luggage.local
-include $(LUGGAGE_LOCAL)


# target stanzas

help::
	@-echo
	@-echo "Usage"
	@-echo
	@-echo "make clean - clean up work files."
	@-echo "make dmg   - roll a pkg, then stuff it into a dmg file."
	@-echo "make zip   - roll a pkg, then stuff it into a zip file."
	@-echo "make pkg   - roll a pkg."
	@-echo "make pkgls - list the bill of materials that will be generated by the pkg."
	@-echo

# set up some work directories

payload_d:
	@sudo mkdir -p ${PAYLOAD_D}

package_root:
	@sudo mkdir -p ${WORK_D}

# packagemaker chokes if the pkg doesn't contain any payload, making script-only
# packages fail to build mysteriously if you don't remember to include something
# in it, so we're including the /usr/local directory, since it's harmless.
# this pseudo_payload can easily be overridden in your makefile

ifeq (${USE_PKGBUILD}, 0)
pseudo_payload: l_usr_local;
else
pseudo_payload: ;
endif

scriptdir: pseudo_payload
	@sudo mkdir -p ${SCRIPT_D}

resourcedir:
	@sudo mkdir -p ${RESOURCE_D}

builddir:
	@sudo mkdir -p ${BUILD_D}
	@sudo chmod 755 ${BUILD_D}
	@sudo chown ${USER} ${BUILD_D}

# add sidecar items, not install payload, into the Resources directory
# sidecar items may support the installer: welcome file, strings files
# sidecar items may also be used by scripts but not installed
enlprojdir: resourcedir
	@sudo mkdir -p ${EN_LPROJ_D}

scratchdir:
	@sudo mkdir -p ${SCRATCH_D}

outputdir:
	[[ ${OUTPUT_D} == "." ]] || sudo mkdir -p ${OUTPUT_D}
	[[ ${OUTPUT_D} == "." ]] || sudo chmod 775 ${OUTPUT_D}

# user targets

clean:
	@sudo rm -fr ${SCRATCH_D} .luggage.pkg.plist ${PACKAGE_PLIST}

superclean:
	@sudo rm -fr ${LUGGAGE_TMP}

dmg: scratchdir outputdir compile_package
	@echo "Wrapping ${PACKAGE_NAME}..."
	@sudo hdiutil create -volname ${PACKAGE_NAME} \
		-srcfolder ${PAYLOAD_D} \
		-uid 99 -gid 99 \
		-ov \
		-format ${DMG_FORMAT} \
		${SCRATCH_D}/${DMG_NAME}
	sudo ${CP} ${SCRATCH_D}/${DMG_NAME} ${OUTPUT_D}/

zip: scratchdir compile_package
	@echo "Zipping ${PACKAGE_NAME}..."
	@${DITTO} -c -k \
		--noqtn --noacl \
		--sequesterRsrc \
		${PAYLOAD_D} \
		${SCRATCH_D}/${ZIP_NAME}
	sudo ${CP} ${SCRATCH_D}/${ZIP_NAME} ${OUTPUT_D}/

modify_packageroot:
	@echo "If you need to override permissions or ownerships, override modify_packageroot in your Makefile"

prep_pkg: compile_package

pkg: outputdir prep_pkg

pkg-dist: prep_pkg create_flatdist

ifeq (${USE_PKGBUILD}, 0)
pkgls: pkgls_pm ;
else
pkgls: pkgls_pb ;
endif

pkgls_pm: prep_pkg
	@echo
	@echo
	lsbom -p fmUG ${PAYLOAD_D}/${PACKAGE_FILE}/Contents/Archive.bom

pkgls_pb: prep_pkg
	@echo
	@echo
	lsbom -p fmUG `pkgutil --bom ${PAYLOAD_D}/${PACKAGE_FILE}`

payload: payload_d package_root scratchdir scriptdir resourcedir
	$(MAKE) -f $(word 1,$(MAKEFILE_LIST)) -e ${PAYLOAD}
	@-echo

compile_package_pm: payload .luggage.pkg.plist modify_packageroot
	@-sudo rm -fr ${PAYLOAD_D}/${PACKAGE_FILE}
	@echo "Creating ${PAYLOAD_D}/${PACKAGE_FILE} with ${PACKAGEMAKER}"
	sudo ${PACKAGEMAKER} --root ${WORK_D} \
		--id ${PACKAGE_ID} \
		${PM_FILTER} \
		--target ${PACKAGE_TARGET_OS} \
		--title ${TITLE} \
		--info ${SCRATCH_D}/luggage.pkg.plist \
		--scripts ${SCRIPT_D} \
		--resources ${RESOURCE_D} \
		--version ${PACKAGE_VERSION} \
		${PM_EXTRA_ARGS} --out ${PAYLOAD_D}/${PACKAGE_FILE}
	sudo ${CP} ${PAYLOAD_D}/${PACKAGE_FILE} ${OUTPUT_D}/

compile_package_pb: payload .luggage.pkg.component.plist kill_relocate modify_packageroot
	@-sudo rm -fr ${PAYLOAD_D}/${PACKAGE_FILE}
	@echo "Creating ${PAYLOAD_D}/${PACKAGE_FILE} with ${PKGBUILD}."
	sudo ${PKGBUILD} --root ${WORK_D} \
		--component-plist ${SCRATCH_D}/luggage.pkg.component.plist \
		--identifier ${PACKAGE_ID} \
		${PM_FILTER} \
		--scripts ${SCRIPT_D} \
		--version ${PACKAGE_VERSION} \
		${PB_EXTRA_ARGS} \
		${PAYLOAD_D}/${PACKAGE_FILE}
	sudo ${CP} ${PAYLOAD_D}/${PACKAGE_FILE} ${OUTPUT_D}/

create_flatdist:
	@-sudo rm -fr ${PAYLOAD_D}/${PKG_DIST}
	@echo "Creating flat distribution package ${PKG_DIST}..."
	@-sudo ${PRODUCTBUILD} --quiet \
	--package ${PAYLOAD_D}/${PACKAGE_FILE} \
	${PAYLOAD_D}/${PKG_DIST}
	sudo ${CP} -R ${PAYLOAD_D}/${PKG_DIST} ${OUTPUT_D}/

ifeq (${USE_PKGBUILD}, 0)
compile_package: compile_package_pm ;
else
compile_package: compile_package_pb ;
endif

${PACKAGE_PLIST}: ${PLIST_PATH}
# override this stanza if you have a different plist you want to use as
# a custom local template.
	@cat ${PLIST_PATH} > ${OUTPUT_D}/${PACKAGE_PLIST}

.luggage.pkg.plist: ${PACKAGE_PLIST}
	@cat ${PACKAGE_PLIST} | \
		sed "s/{DD}/${DD}/g" | \
		sed "s/{MM}/${MM}/g" | \
		sed "s/{YY}/${YY}/g" | \
		sed "s/{PACKAGE_MAJOR_VERSION}/${PACKAGE_MAJOR_VERSION}/g" | \
		sed "s/{PACKAGE_MINOR_VERSION}/${PACKAGE_MINOR_VERSION}/g" | \
		sed "s/{BUILD_DATE}/${BUILD_DATE}/g" | \
		sed "s/{PACKAGE_ID}/${PACKAGE_ID}/g" | \
		sed "s/{PACKAGE_VERSION}/${PACKAGE_VERSION}/g" | \
		sed "s/{PM_RESTART}/${PM_RESTART}/g" | \
		sed "s/{PLIST_FLAVOR}/${PLIST_FLAVOR}/g" | \
		sed "s/{ROOT_ONLY}/${ROOT_ONLY}/g" \
		> ${SCRATCH_D}/.luggage.pkg.plist
	@sudo ${CP} ${SCRATCH_D}/.luggage.pkg.plist ${SCRATCH_D}/luggage.pkg.plist
	@rm ${SCRATCH_D}/.luggage.pkg.plist ${PACKAGE_PLIST}

.luggage.pkg.component.plist:
	@sudo ${PKGBUILD} --quiet --analyze --root ${WORK_D} \
		${PM_FILTER} \
		${SCRATCH_D}/luggage.pkg.component.plist
	@if [[ ! -f ${SCRATCH_D}/luggage.pkg.component.plist ]]; then echo "Error disabling bundle relocation: No component plist found!" 2>&1; else \
	echo "Disabling bundle relocation." 2>&1;\
	fi

define PYTHON_PLISTER
import plistlib
component = plistlib.readPlist('${SCRATCH_D}/luggage.pkg.component.plist')
for payload in component:
    if payload.get('BundleIsRelocatable'):
        payload['BundleIsRelocatable'] = False
plistlib.writePlist(component, '${SCRATCH_D}/luggage.pkg.component.plist')
endef

export PYTHON_PLISTER

kill_relocate:
	@-sudo /usr/bin/python -c "$${PYTHON_PLISTER}"

# Target directory rules

l_root: package_root
	@sudo mkdir -p ${WORK_D}
	@sudo chmod 755 ${WORK_D}
	@sudo chown root:wheel ${WORK_D}

l_private: l_root
	@sudo mkdir -p ${WORK_D}/private
	@sudo chown -R root:wheel ${WORK_D}/private
	@sudo chmod -R 755 ${WORK_D}/private

l_private_bin: l_private
	@sudo mkdir -p ${WORK_D}/private/bin
	@sudo chown -R root:wheel ${WORK_D}/private/bin
	@sudo chmod -R 755 ${WORK_D}/private/bin

l_private_etc: l_private
	@sudo mkdir -p ${WORK_D}/private/etc
	@sudo chown -R root:wheel ${WORK_D}/private/etc
	@sudo chmod -R 755 ${WORK_D}/private/etc

l_private_sbin: l_private
	@sudo mkdir -p ${WORK_D}/private/sbin
	@sudo chown -R root:wheel ${WORK_D}/private/sbin
	@sudo chmod -R 755 ${WORK_D}/private/sbin

l_private_etc_hooks: l_etc_hooks

l_private_etc_openldap: l_etc_openldap

l_private_etc_puppet: l_etc_puppet

l_private_var: l_var

l_private_var_lib: l_var_lib

l_private_var_lib_puppet: l_var_lib_puppet

l_private_var_db: l_var_db

l_private_var_db_dslocal: l_var_db_dslocal

l_private_var_db_dslocal_nodes: l_var_db_dslocal_nodes

l_private_var_db_dslocal_nodes_Default: l_var_db_dslocal_nodes_Default

l_private_var_db_dslocal_nodes_Default_groups: l_var_db_dslocal_nodes_Default_groups

l_private_var_db_dslocal_nodes_Default_users: l_var_db_dslocal_nodes_Default_users

l_private_var_root: l_var_root

l_private_var_root_Library: l_var_root_Library

l_private_var_root_Library_Preferences: l_var_root_Library_Preferences

l_etc_hooks: l_private_etc
	@sudo mkdir -p ${WORK_D}/private/etc/hooks
	@sudo chown -R root:wheel ${WORK_D}/private/etc/hooks
	@sudo chmod -R 755 ${WORK_D}/private/etc/hooks

l_etc_openldap: l_private_etc
	@sudo mkdir -p ${WORK_D}/private/etc/openldap
	@sudo chmod 755 ${WORK_D}/private/etc/openldap
	@sudo chown root:wheel ${WORK_D}/private/etc/openldap

l_etc_puppet: l_private_etc
	@sudo mkdir -p ${WORK_D}/private/etc/puppet
	@sudo chown -R root:wheel ${WORK_D}/private/etc/puppet
	@sudo chmod -R 755 ${WORK_D}/private/etc/puppet

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

l_usr_lib_ruby_site_ruby_1_8: l_usr
	@sudo mkdir -p ${WORK_D}/usr/lib/ruby/site_ruby/1.8
	@sudo chown -R root:wheel ${WORK_D}/usr/lib/ruby/site_ruby/1.8
	@sudo chmod -R 755 ${WORK_D}/usr/lib/ruby/site_ruby/1.8

l_usr_local: l_usr
	@sudo mkdir -p ${WORK_D}/usr/local
	@sudo chown -R root:wheel ${WORK_D}/usr/local
	@sudo chmod -R 755 ${WORK_D}/usr/local

l_usr_local_bin: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/bin
	@sudo chown -R root:wheel ${WORK_D}/usr/local/bin
	@sudo chmod -R 755 ${WORK_D}/usr/local/bin

l_usr_local_include: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/include
	@sudo chown -R root:wheel ${WORK_D}/usr/local/include
	@sudo chmod -R 755 ${WORK_D}/usr/local/include

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

l_usr_man: l_usr_share
	@sudo mkdir -p ${WORK_D}/usr/share/man
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man

l_usr_man_man1: l_usr_man
	@sudo mkdir -p ${WORK_D}/usr/share/man/man1
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man/man1
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man/man1

l_usr_man_man2: l_usr_man
	@sudo mkdir -p ${WORK_D}/usr/share/man/man2
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man/man2
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man/man2

l_usr_man_man3: l_usr_man
	@sudo mkdir -p ${WORK_D}/usr/share/man/man3
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man/man3
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man/man3

l_usr_man_man4: l_usr_man
	@sudo mkdir -p ${WORK_D}/usr/share/man/man4
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man/man4
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man/man4

l_usr_man_man5: l_usr_man
	@sudo mkdir -p ${WORK_D}/usr/share/man/man5
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man/man5
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man/man5

l_usr_man_man6: l_usr_man
	@sudo mkdir -p ${WORK_D}/usr/share/man/man6
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man/man6
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man/man6

l_usr_man_man7: l_usr_man
	@sudo mkdir -p ${WORK_D}/usr/share/man/man7
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man/man7
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man/man7

l_usr_man_man8: l_usr_man
	@sudo mkdir -p ${WORK_D}/usr/share/man/man8
	@sudo chown -R root:wheel ${WORK_D}/usr/share/man/man8
	@sudo chmod -R 0755 ${WORK_D}/usr/share/man/man8

l_usr_sbin: l_usr
	@sudo mkdir -p ${WORK_D}/usr/sbin
	@sudo chown -R root:wheel ${WORK_D}/usr/sbin
	@sudo chmod -R 755 ${WORK_D}/usr/sbin

l_usr_share: l_usr
	@sudo mkdir -p ${WORK_D}/usr/share
	@sudo chown -R root:wheel ${WORK_D}/usr/share
	@sudo chmod -R 755 ${WORK_D}/usr/share

l_usr_share_doc: l_usr_share
	@sudo mkdir -p ${WORK_D}/usr/share/doc
	@sudo chown -R root:wheel ${WORK_D}/usr/share/doc
	@sudo chmod -R 755 ${WORK_D}/usr/share/doc

l_var: l_private
	@sudo mkdir -p ${WORK_D}/private/var
	@sudo chown -R root:wheel ${WORK_D}/private/var
	@sudo chmod -R 755 ${WORK_D}/private/var

l_var_lib: l_root
	@sudo mkdir -p ${WORK_D}/private/var/lib
	@sudo chown -R root:wheel ${WORK_D}/private/var/lib
	@sudo chmod -R 755 ${WORK_D}/private/var/lib

l_var_lib_puppet: l_root
	@sudo mkdir -p ${WORK_D}/private/var/lib/puppet
	@sudo chown -R root:wheel ${WORK_D}/private/var/lib/puppet
	@sudo chmod -R 755 ${WORK_D}/private/var/lib/puppet

l_var_db: l_var
	@sudo mkdir -p ${WORK_D}/private/var/db
	@sudo chown -R root:wheel ${WORK_D}/private/var/db
	@sudo chmod -R 755 ${WORK_D}/private/var/db

l_var_db_ConfigurationProfiles: l_var_db
	@sudo mkdir -p ${WORK_D}/private/var/db/ConfigurationProfiles
	@sudo chown root:wheel ${WORK_D}/private/var/db/ConfigurationProfiles
	@sudo chmod 755 ${WORK_D}/private/var/db/ConfigurationProfiles

l_var_db_ConfigurationProfiles_Setup: l_var_db_ConfigurationProfiles
	@sudo mkdir -p ${WORK_D}/private/var/db/ConfigurationProfiles/Setup
	@sudo chown root:wheel ${WORK_D}/private/var/db/ConfigurationProfiles/Setup
	@sudo chmod 700 ${WORK_D}/private/var/db/ConfigurationProfiles/Setup

l_var_db_dslocal: l_var_db
	@sudo mkdir -p ${WORK_D}/private/var/db/dslocal
	@sudo chown -R root:wheel ${WORK_D}/private/var/db/dslocal
	@sudo chmod -R 755 ${WORK_D}/private/var/db/dslocal

l_var_db_dslocal_nodes: l_var_db_dslocal
	@sudo mkdir -p ${WORK_D}/private/var/db/dslocal/nodes
	@sudo chown -R root:wheel ${WORK_D}/private/var/db/dslocal/nodes
	@sudo chmod -R 755 ${WORK_D}/private/var/db/dslocal/nodes

l_var_db_dslocal_nodes_Default: l_var_db_dslocal_nodes
	@sudo mkdir -p ${WORK_D}/private/var/db/dslocal/nodes/Default
	@sudo chown -R root:wheel ${WORK_D}/private/var/db/dslocal/nodes/Default
	@sudo chmod -R 600 ${WORK_D}/private/var/db/dslocal/nodes/Default

l_var_db_dslocal_nodes_Default_groups: l_var_db_dslocal_nodes_Default
	@sudo mkdir -p ${WORK_D}/private/var/db/dslocal/nodes/Default/groups
	@sudo chown -R root:wheel ${WORK_D}/private/var/db/dslocal/nodes/Default/groups
	@sudo chmod -R 700 ${WORK_D}/private/var/db/dslocal/nodes/Default/groups

l_var_db_dslocal_nodes_Default_users: l_var_db_dslocal_nodes_Default
	@sudo mkdir -p ${WORK_D}/private/var/db/dslocal/nodes/Default/users
	@sudo chown -R root:wheel ${WORK_D}/private/var/db/dslocal/nodes/Default/users
	@sudo chmod -R 700 ${WORK_D}/private/var/db/dslocal/nodes/Default/users

l_var_root: l_var
	@sudo mkdir -p ${WORK_D}/private/var/root
	@sudo chown -R root:wheel ${WORK_D}/private/var/root
	@sudo chmod -R 750 ${WORK_D}/private/var/root

l_var_root_Library: l_var_root
	@sudo mkdir -p ${WORK_D}/private/var/root/Library
	@sudo chown -R root:wheel ${WORK_D}/private/var/root/Library
	@sudo chmod -R 700 ${WORK_D}/private/var/root/Library

l_var_root_Library_Preferences: l_var_root_Library
	@sudo mkdir -p ${WORK_D}/private/var/root/Library/Preferences
	@sudo chown -R root:wheel ${WORK_D}/private/var/root/Library/Preferences
	@sudo chmod -R 700 ${WORK_D}/private/var/root/Library/Preferences

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

l_Library_Application_Support: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Application\ Support
	@sudo chown root:admin ${WORK_D}/Library/Application\ Support
	@sudo chmod 755 ${WORK_D}/Library/Application\ Support

l_Library_Application_Support_Adobe: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Application\ Support/Adobe
	@sudo chown root:admin ${WORK_D}/Library/Application\ Support/Adobe
	@sudo chmod 775 ${WORK_D}/Library/Application\ Support/Adobe

l_Library_Application_Support_Oracle: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Application\ Support/Oracle
	@sudo chown root:admin ${WORK_D}/Library/Application\ Support/Oracle
	@sudo chmod 755 ${WORK_D}/Library/Application\ Support/Oracle

l_Library_Application_Support_Oracle_Java: l_Library_Application_Support_Oracle
	@sudo mkdir -p ${WORK_D}/Library/Application\ Support/Oracle/Java
	@sudo chown root:admin ${WORK_D}/Library/Application\ Support/Oracle/Java
	@sudo chmod 755 ${WORK_D}/Library/Application\ Support/Oracle/Java

l_Library_Application_Support_Oracle_Java_Deployment: l_Library_Application_Support_Oracle_Java
	@sudo mkdir -p ${WORK_D}/Library/Application\ Support/Oracle/Java/Deployment
	@sudo chown root:admin ${WORK_D}/Library/Application\ Support/Oracle/Java/Deployment
	@sudo chmod 755 ${WORK_D}/Library/Application\ Support/Oracle/Java/Deployment

l_Library_Desktop_Pictures: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Desktop\ Pictures
	@sudo chown root:admin ${WORK_D}/Library/Desktop\ Pictures
	@sudo chmod 775 ${WORK_D}/Library/Desktop\ Pictures

l_Library_Fonts: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Fonts
	@sudo chown root:admin ${WORK_D}/Library/Fonts
	@sudo chmod 775 ${WORK_D}/Library/Fonts

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

l_Library_Preferences_OpenDirectory: l_Library_Preferences
	@sudo mkdir -p ${WORK_D}/Library/Preferences/OpenDirectory
	@sudo chown root:wheel ${WORK_D}/Library/Preferences/OpenDirectory
	@sudo chmod 755 ${WORK_D}/Library/Preferences/OpenDirectory

l_Library_Preferences_OpenDirectory_Configurations: l_Library_Preferences_OpenDirectory
	@sudo mkdir -p ${WORK_D}/Library/Preferences/OpenDirectory/Configurations
	@sudo chown root:wheel ${WORK_D}/Library/Preferences/OpenDirectory/Configurations
	@sudo chmod 755 ${WORK_D}/Library/Preferences/OpenDirectory/Configurations

l_Library_Preferences_OpenDirectory_Configurations_LDAPv3: l_Library_Preferences_OpenDirectory_Configurations
	@sudo mkdir -p ${WORK_D}/Library/Preferences/OpenDirectory/Configurations/LDAPv3
	@sudo chown root:wheel ${WORK_D}/Library/Preferences/OpenDirectory/Configurations/LDAPv3
	@sudo chmod 750 ${WORK_D}/Library/Preferences/OpenDirectory/Configurations/LDAPv3

l_Library_Preferences_DirectoryService: l_Library_Preferences
	@sudo mkdir -p ${WORK_D}/Library/Preferences/DirectoryService
	@sudo chown root:admin ${WORK_D}/Library/Preferences/DirectoryService
	@sudo chmod 775 ${WORK_D}/Library/Preferences/DirectoryService

l_Library_PreferencePanes: l_Library
	@sudo mkdir -p ${WORK_D}/Library/PreferencePanes
	@sudo chown root:wheel ${WORK_D}/Library/PreferencePanes
	@sudo chmod 755 ${WORK_D}/Library/PreferencePanes

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

l_Library_ScreenSavers: l_Library
	@sudo mkdir -p ${WORK_D}/Library/Screen\ Savers
	@sudo chown root:wheel ${WORK_D}/Library/Screen\ Savers
	@sudo chmod 755 ${WORK_D}/Library/Screen\ Savers

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

l_Library_StartupItems: l_Library
	@sudo mkdir -p ${WORK_D}/Library/StartupItems
	@sudo chown root:wheel ${WORK_D}/Library/StartupItems
	@sudo chmod 755 ${WORK_D}/Library/StartupItems

l_System: l_root
	@sudo mkdir -p ${WORK_D}/System
	@sudo chown -R root:wheel ${WORK_D}/System
	@sudo chmod -R 755 ${WORK_D}/System

l_System_Library: l_System
	@sudo mkdir -p ${WORK_D}/System/Library
	@sudo chown -R root:wheel ${WORK_D}/System/Library
	@sudo chmod -R 755 ${WORK_D}/System/Library

l_System_Library_Extensions: l_System_Library
	@sudo mkdir -p ${WORK_D}/System/Library/Extensions
	@sudo chown -R root:wheel ${WORK_D}/System/Library/Extensions
	@sudo chmod -R 755 ${WORK_D}/System/Library/Extensions

l_System_Library_User_Template: l_System_Library
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj
	@sudo chown -R root:wheel ${USER_TEMPLATE}/English.lproj
	@sudo chmod 700 ${USER_TEMPLATE}
	@sudo chmod -R 755 ${USER_TEMPLATE}/English.lproj

l_System_Library_User_Template_Library: l_System_Library_User_Template
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj/Library
	@sudo chown root:wheel ${USER_TEMPLATE}/English.lproj/Library
	@sudo chmod 700 ${USER_TEMPLATE}/English.lproj/Library

l_System_Library_User_Template_Pictures: l_System_Library_User_Template
	@sudo mkdir -p ${USER_TEMPLATE_PICTURES}
	@sudo chown root:wheel ${USER_TEMPLATE_PICTURES}
	@sudo chmod 700 ${USER_TEMPLATE_PICTURES}

l_System_Library_User_Template_Preferences: l_System_Library_User_Template_Library
	@sudo mkdir -p ${USER_TEMPLATE_PREFERENCES}
	@sudo chown root:wheel ${USER_TEMPLATE_PREFERENCES}
	@sudo chmod -R 700 ${USER_TEMPLATE_PREFERENCES}

l_System_Library_User_Template_Library_Application_Support: l_System_Library_User_Template_Library
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj/Library/Application\ Support
	@sudo chown root:wheel ${USER_TEMPLATE}/English.lproj/Library/Application\ Support
	@sudo chmod 700 ${USER_TEMPLATE}/English.lproj/Library/Application\ Support

l_System_Library_User_Template_Library_Application_Support_Firefox: l_System_Library_User_Template_Library_Application_Support
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox
	@sudo chown root:wheel ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox
	@sudo chmod 700 ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox

l_System_Library_User_Template_Library_Application_Support_Firefox_Profiles: l_System_Library_User_Template_Library_Application_Support_Firefox
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox/Profiles
	@sudo chown root:wheel ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox/Profiles
	@sudo chmod 700 ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox/Profiles

l_System_Library_User_Template_Library_Application_Support_Firefox_Profiles_Default: l_System_Library_User_Template_Library_Application_Support_Firefox_Profiles
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox/Profiles/a7e8aa9f.default
	@sudo chown root:wheel ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox/Profiles/a7e8aa9f.default
	@sudo chmod 700 ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox/Profiles/a7e8aa9f.default

l_System_Library_User_Template_Library_Application_Support_Oracle: l_System_Library_User_Template_Library
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle
	@sudo chown root:wheel ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle
	@sudo chmod 700 ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle

l_System_Library_User_Template_Library_Application_Support_Oracle_Java: l_System_Library_User_Template_Library_Application_Support_Oracle
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle/Java
	@sudo chown root:wheel ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle/Java
	@sudo chmod 700 ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle/Java

l_System_Library_User_Template_Library_Application_Support_Oracle_Java_Deployment: l_System_Library_User_Template_Library_Application_Support_Oracle_Java
	@sudo mkdir -p ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle/Java/Deployment
	@sudo chown root:wheel ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle/Java/Deployment
	@sudo chmod 700 ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle/Java/Deployment

# These user domain locations are for use in rare circumstances, and
# as a last resort only for repackaging applications that use them.
# A notice will be issued during the build process.
l_Users: l_root
	@sudo mkdir -p ${WORK_D}/Users
	@sudo chown root:admin ${WORK_D}/Users
	@sudo chmod 755 ${WORK_D}/Users
	@echo "Creating \"Users\" directory"

l_Users_Shared: l_Users
	@sudo mkdir -p ${WORK_D}/Users/Shared
	@sudo chown root:wheel ${WORK_D}/Users/Shared
	@sudo chmod 1777 ${WORK_D}/Users/Shared
	@echo "Creating \"Users/Shared\" directory"

# file packaging rules
bundle-%: % payload_d
	sudo ${CP} "${<}" ${PAYLOAD_D}

pack-open-directory-%: % l_Library_Preferences_OpenDirectory
	sudo install -m 600 -o root -g wheel "${<}" ${WORK_D}/Library/Preferences/OpenDirectory

pack-open-directory-configurations-%: % l_Library_Preferences_OpenDirectory_Configurations
	sudo install -m 600 -o root -g wheel "${<}" ${WORK_D}/Library/Preferences/OpenDirectory/Configurations

pack-open-directory-configurations-ldapv3-%: % l_Library_Preferences_OpenDirectory_Configurations_LDAPv3
	sudo install -m 600 -o root -g wheel "${<}" ${WORK_D}/Library/Preferences/OpenDirectory/Configurations/LDAPv3

pack-directory-service-preference-%: % l_Library_Preferences_DirectoryService
	sudo install -m 600 -o root -g admin "${<}" ${WORK_D}/Library/Preferences/DirectoryService

pack-site-python-%: % l_Library_Python_26_site_packages
	@sudo ${INSTALL} -m 644 -g admin -o root "${<}" ${WORK_D}/Library/Python/2.6/site-packages

pack-siteruby-%: % l_Library_Ruby_Site_1_8
	@sudo ${INSTALL} -m 644 -g wheel -o root "${<}" ${WORK_D}/Library/Ruby/Site/1.8

pack-Library-Application-Support-Oracle-Java-Deployment-%: % l_Library_Application_Support_Oracle_Java_Deployment
	@sudo ${INSTALL} -m 644 -g admin -o root "${<}" ${WORK_D}/Library/Application\ Support/Oracle/Java/Deployment

pack-Library-Fonts-%: % l_Library_Fonts
	@sudo ${INSTALL} -m 664 -g admin -o root "${<}" ${WORK_D}/Library/Fonts

pack-Library-LaunchAgents-%: % l_Library_LaunchAgents
	@sudo ${INSTALL} -m 644 -g wheel -o root "${<}" ${WORK_D}/Library/LaunchAgents

pack-Library-LaunchDaemons-%: % l_Library_LaunchDaemons
	@sudo ${INSTALL} -m 644 -g wheel -o root "${<}" ${WORK_D}/Library/LaunchDaemons

pack-Library-Preferences-%: % l_Library_Preferences
	@sudo ${INSTALL} -m 644 -g admin -o root "${<}" ${WORK_D}/Library/Preferences

pack-Library-ScreenSavers-%: % l_Library_ScreenSavers
	@sudo ${DITTO} --noqtn "${<}" ${WORK_D}/Library/Screen\ Savers/"${<}"
	@sudo chown -R root:wheel ${WORK_D}/Library/Screen\ Savers/"${<}"
	@sudo chmod 755 ${WORK_D}/Library/Screen\ Savers/"${<}"

pack-ppd-%: % l_PPDs
	@sudo ${INSTALL} -m 664 -g admin -o root "${<}" ${WORK_D}/Library/Printers/PPDs/Contents/Resources

pack-script-pb-%: % scriptdir
	@echo "******************************************************************"
	@echo ""
	@echo "Using ${PKGBUILD}, make sure scripts are"
	@echo "named preinstall/postinstall"
	@echo ""
	@echo "Also check your pack-script-* stanzas in PAYLOAD"
	@echo ""
	@echo "******************************************************************"
	@sudo ${INSTALL} -o root -g wheel -m 755 "${<}" ${SCRIPT_D}

pack-script-pm-%: % scriptdir
	@echo "******************************************************************"
	@echo ""
	@echo "Using ${PACKAGEMAKER}, make sure script names and PAYLOAD are"
	@echo "named preflight/postflight"
	@echo ""
	@echo "Also check your pack-script-* stanzas in PAYLOAD"
	@echo ""
	@echo "******************************************************************"
	@sudo ${INSTALL} -o root -g wheel -m 755 "${<}" ${SCRIPT_D}

ifeq (${USE_PKGBUILD}, 0)
pack-script-%: pack-script-pm-% ;
else
pack-script-%: pack-script-pb-% ;
endif


pack-resource-%: % resourcedir
	@sudo ${INSTALL} -m 755 "${<}" ${RESOURCE_D}

pack-en-resource-%: % enlprojdir
	@echo "Packing a non-payload item into the installer Resources directory."
	@sudo ${INSTALL} -m 755 "${<}" ${EN_LPROJ_D}

pack-user-template-plist-%: % l_System_Library_User_Template_Preferences
	@sudo ${INSTALL} -m 644 "${<}" ${USER_TEMPLATE_PREFERENCES}

pack-user-picture-%: % l_Library_Desktop_Pictures
	@sudo ${INSTALL} -m 644 "${<}" ${WORK_D}/Library/Desktop\ Pictures

pack-User-Template-Library-Application-Support-Firefox-Profiles-Default-%: % l_System_Library_User_Template_Library_Application_Support_Firefox_Profiles_Default
	@sudo ${INSTALL} -m 644 "${<}" ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Firefox/Profiles/a7e8aa9f.default

pack-User-Template-Library-Application-Support-Oracle-Java-Deployment-%: % l_System_Library_User_Template_Library_Application_Support_Oracle_Java_Deployment
	@sudo ${INSTALL} -m 644 -g wheel -o root "${<}" ${USER_TEMPLATE}/English.lproj/Library/Application\ Support/Oracle/Java/Deployment

# posixy file stanzas

pack-bin-%: % l_private_bin
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/private/bin

pack-etc-%: % l_private_etc
	@sudo ${INSTALL} -m 644 -g wheel -o root "${<}" ${WORK_D}/private/etc

pack-etc-openldap-%: % l_etc_openldap
	@sudo install -m 644 -o root -g wheel "${<}" "${PKGROOT}"/etc/openldap

pack-sbin-%: % l_private_sbin
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/private/sbin

pack-usr-bin-%: % l_usr_bin
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/bin

pack-usr-sbin-%: % l_usr_sbin
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/sbin

pack-usr-local-bin-%: % l_usr_local_bin
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/bin

pack-usr-local-sbin-%: % l_usr_local_sbin
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/sbin

pack-var-db-ConfigurationProfiles-Setup-%: % l_var_db_ConfigurationProfiles_Setup
	sudo ${INSTALL} -m 644 "${<}" ${WORK_D}/private/var/db/ConfigurationProfiles/Setup

pack-var-db-dslocal-nodes-Default-groups-%: % l_private_var_db_dslocal_nodes_Default_groups
	@echo "Packing file ${<} into the DSLocal Default node."
	@echo "You may wish to consider alternatives to this."
	@sudo ${INSTALL} -m 600 -g wheel -o root "${<}" ${WORK_D}/private/var/db/dslocal/nodes/Default/groups

pack-var-db-dslocal-nodes-Default-users-%: % l_private_var_db_dslocal_nodes_Default_users
	@echo "Packing file ${<} into the DSLocal Default node."
	@echo "You may wish to consider alternatives to this."
	@sudo ${INSTALL} -m 600 -g wheel -o root "${<}" ${WORK_D}/private/var/db/dslocal/nodes/Default/users

pack-var-root-Library-Preferences-%: % l_private_var_root_Library_Preferences
	@sudo ${INSTALL} -m 600 -g wheel -o root "${<}" ${WORK_D}/private/var/root/Library/Preferences

pack-man-%: % l_usr_man
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man

pack-man1-%: % l_usr_man_man1
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man/man1

pack-man2-%: % l_usr_man_man2
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man/man2

pack-man3-%: % l_usr_man_man3
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man/man3

pack-man4-%: % l_usr_man_man4
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man/man4

pack-man5-%: % l_usr_man_man5
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man/man5

pack-man6-%: % l_usr_man_man6
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man/man6

pack-man7-%: % l_usr_man_man7
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man/man7

pack-man8-%: % l_usr_man_man8
	@sudo ${INSTALL} -m 0644 -g wheel -o root "${<}" ${WORK_D}/usr/share/man/man8

pack-hookscript-%: % l_private_etc_hooks
	@sudo ${INSTALL} -m 755 "${<}" ${WORK_D}/private/etc/hooks

# Applications and Utilities
#
# We use ${TAR} because it respects resource forks. This is still
# critical - just when I thought I'd seen the last of the damn things, Apple
# decided to stash compressed binaries in them in 10.6.

unbz2-applications-%: %.tar.bz2 l_Applications
	@sudo ${TAR} xjf "${<}" -C ${WORK_D}/Applications
	@sudo chown -R root:admin ${WORK_D}/Applications/"$(shell echo "${<}" | sed s/\.tar\.bz2//g)"

unbz2-utilities-%: %.tar.bz2 l_Applications_Utilities
	@sudo ${TAR} xjf "${<}" -C ${WORK_D}/Applications/Utilities
	@sudo chown -R root:admin ${WORK_D}/Applications/Utilities/"$(shell echo "${<}" | sed s/\.tar\.bz2//g)"

unbz2-preferencepanes-%: %.tar.bz2 l_Library_PreferencePanes
	@sudo ${TAR} xjf "${<}" -C ${WORK_D}/Library/PreferencePanes
	@sudo chown -R root:admin ${WORK_D}/Library/PreferencePanes/"$(shell echo "${<}" | sed s/\.tar\.bz2//g)"

ungz-applications-%: %.tar.gz l_Applications
	@sudo ${TAR} xzf "${<}" -C ${WORK_D}/Applications
	@sudo chown -R root:admin ${WORK_D}/Applications/"$(shell echo "${<}" | sed s/\.tar\.gz//g)"

ungz-utilities-%: %.tar.gz l_Applications_Utilities
	@sudo ${TAR} xzf "${<}" -C ${WORK_D}/Applications/Utilities
	@sudo chown -R root:admin ${WORK_D}/Applications/Utilities/"$(shell echo "${<}" | sed s/\.tar\.gz//g)"

# ${DITTO} preserves resource forks by default
# --noqtn drops quarantine information

# Allow for packaging software in the same working directory as the Makefile
pack-applications-%: % l_Applications
	@sudo ${DITTO} --noqtn "${<}" ${WORK_D}/Applications/"${<}"
	@sudo chown -R root:admin ${WORK_D}/Applications/"${<}"
	@sudo chmod 755 ${WORK_D}/Applications/"${<}"

# Allow for packaging software dirctly from the /Applications directory.
pack-from-applications-%: /Applications/% l_Applications
	@sudo ${DITTO} --noqtn "${<}" ${WORK_D}"${<}"
	@sudo chown -R root:admin ${WORK_D}"${<}"
	@sudo chmod 755 ${WORK_D}"${<}"

pack-utilities-%: % l_Applications_Utilities
	@sudo ${DITTO} --noqtn "${<}" ${WORK_D}/Applications/Utilities/"${<}"
	@sudo chown -R root:admin ${WORK_D}/Applications/Utilities/"${<}"
	@sudo chmod 755 ${WORK_D}/Applications/Utilities/"${<}"

pack-preferencepanes-%: % l_Library_PreferencePanes
	@sudo ${DITTO} --noqtn "${<}" ${WORK_D}/Library/PreferencePanes/"${<}"
	@sudo chown -R root:admin ${WORK_D}/Library/PreferencePanes/"${<}"
	@sudo chmod 755 ${WORK_D}/Library/PreferencePanes/"${<}"

pack-from-preferencepanes-%: /Library/PreferencePanes/% l_Library_PreferencePanes
	@sudo ${DITTO} --noqtn "${<}" ${WORK_D}"${<}"
	@sudo chown -R root:admin ${WORK_D}"${<}"
	@sudo chmod 755 ${WORK_D}"${<}"

# -k -x extracts zip
# Zipped applications commonly found on the Web usually have the suffixes substituted, so these stanzas substitute them back

unzip-applications-%: %.zip l_Applications
	@sudo ${DITTO} --noqtn -k -x "${<}" ${WORK_D}/Applications/
	@sudo chown -R root:admin ${WORK_D}/Applications/$(shell echo "${<}" | sed s/\.zip/.app/g)

unzip-utilities-%: %.zip l_Applications_Utilities
	@sudo ${DITTO} --noqtn -k -x "${<}" ${WORK_D}/Applications/Utilities/
	@sudo chown -R root:admin ${WORK_D}/Applications/Utilities/$(shell echo "${<}" | sed s/\.zip/.app/g)
