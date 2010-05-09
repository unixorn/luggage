#
#   Copyright 2009 Joe Block <jpb@ApesSeekingKnowledge.net>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#       You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# 
# Example of preconfiguring LDAP settings. You'll have to copy your own
# config files, I'm not including mine :-)

include /usr/local/share/luggage/luggage.make

TITLE=configure_ldap
REVERSE_DOMAIN=com.example.corp
PAYLOAD=\
	pack-ldap.conf \
	pack-directory-service-preference-ContactsNodeConfig.plist \
	pack-directory-service-preference-DSLDAPv3PlugInConfig.plist \
	pack-directory-service-preference-DSRecordTypeRestrictions.plist \
	pack-directory-service-preference-DirectoryService.plist \
	pack-directory-service-preference-SearchNodeConfig.plist

pack-ldap.conf: l_etc_openldap
	@sudo ${INSTALL} -m 644 -o root -g wheel ldap.conf ${WORK_D}/etc/openldap
