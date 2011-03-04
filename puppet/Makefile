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
#  Example:  A dynamic installer for Puppet
#
#  Author:  Gary Larizza
#  Created: 12/17/2010
#  Last Modified: 12/17/2010
#
#  Description:  This Makefile will download the version of Puppet specified
#    in the PACKAGE_VERSION variable from the Puppet Labs website, untar it,
#    and then install the source files into their Mac-specific locations.  
#    The MAJOR and MINOR versions must be specified for the Info.plist file
#    that Packagemaker requires, but I use awk on the PACKAGE_VERSION to 
#    get these.  See inline comments.
#
include /usr/local/share/luggage/luggage.make



TITLE=Puppet_Installer
REVERSE_DOMAIN=com.puppetlabs
PAYLOAD=\
		unpack-puppet-${PUPPETFILE} \
		pack-puppet-etc \
		pack-puppet-usr \
		pack-puppet-preflight
		
# Variable Declarations:  Any variable can be set from the command line by
#    doing this:  "make pkg PACKAGE_VERSION=2.6.2"
PACKAGE_VERSION=2.6.4
PACKAGE_MAJOR_VERSION=`echo ${PACKAGE_VERSION} | awk -F '.' '{print $$1}'`
PACKAGE_MINOR_VERSION=`echo ${PACKAGE_VERSION} | awk -F '.' '{print $$2$$3}'`
PUPPETFILE=puppet-${PACKAGE_VERSION}
PUPPETURL=http://puppetlabs.com/downloads/puppet/${PUPPETFILE}.tar.gz

# The unpack-puppet rule will pull the version of the Puppet source specified
#    by PACKAGE_VERSION into the directory where the Makefile is located. From
#    there we untar it to a directory named puppet-(PACKAGE_VERSION)
unpack-puppet-${PUPPETFILE}:
	curl ${PUPPETURL} -o ${PUPPETFILE}.tar.gz
	@sudo ${TAR} xzf ${PUPPETFILE}.tar.gz

# This rule will copy auth.conf to the /etc/puppet directory
pack-puppet-etc: l_etc_puppet
	@sudo ${CP} ./${PUPPETFILE}/conf/auth.conf ${WORK_D}/etc/puppet/auth.conf
	@sudo chmod 644 ${WORK_D}/etc/puppet/auth.conf
	
# This rule copies the Puppet binaries, libraries, documentation, and manpages
#    to their Mac-specific locations in /usr/ and sets permissions to 755.
pack-puppet-usr: l_usr_bin l_usr_lib_ruby_site_ruby_1_8 l_usr_sbin l_usr_share_doc l_usr_share_man
	@sudo ${CP} -R ./${PUPPETFILE}/bin/ ${WORK_D}/usr/bin/
	@sudo chmod -R 755 ${WORK_D}/usr/bin/
	@sudo ${CP} -R ./${PUPPETFILE}/lib/ ${WORK_D}/usr/lib/ruby/site_ruby/1.8/
	@sudo chmod -R 755 ${WORK_D}/usr/lib/
	@sudo ${CP} -R ./${PUPPETFILE}/sbin/ ${WORK_D}/usr/sbin/
	@sudo chmod -R 755 ${WORK_D}/usr/sbin/
	@sudo ${CP} -R ./${PUPPETFILE}/CHANGELOG ${WORK_D}/usr/share/doc
	@sudo ${CP} -R ./${PUPPETFILE}/CHANGELOG.old ${WORK_D}/usr/share/doc
	@sudo ${CP} -R ./${PUPPETFILE}/COPYING ${WORK_D}/usr/share/doc
	@sudo ${CP} -R ./${PUPPETFILE}/LICENSE ${WORK_D}/usr/share/doc
	@sudo ${CP} -R ./${PUPPETFILE}/README ${WORK_D}/usr/share/doc
	@sudo ${CP} -R ./${PUPPETFILE}/README.queueing ${WORK_D}/usr/share/doc
	@sudo ${CP} -R ./${PUPPETFILE}/README.rst ${WORK_D}/usr/share/doc
	@sudo chmod -R 755 ${WORK_D}/usr/share/doc/
	@sudo ${CP} -R ./${PUPPETFILE}/man/ ${WORK_D}/usr/share/man
	@sudo chmod -R 755 ${WORK_D}/usr/share/man/
	
# This rule sets up the preflight script from the Puppet source's /conf/osx
#    directory and installs it into our scripts directory. From there, we
#    use sed to strip out variables used in the /conf/osx/createpackage.sh
#    script that are unused here.
pack-puppet-preflight:
	@sudo ${INSTALL} -m 755 ./${PUPPETFILE}/conf/osx/preflight ${SCRIPT_D}
	sed -i '' "s#{SITELIBDIR}#/usr/lib/ruby/site_ruby/1.8#g" "${SCRIPT_D}/preflight"
	sed -i '' "s#{BINDIR}#/usr/bin#g" "${SCRIPT_D}/preflight"
	