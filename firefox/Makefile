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
# Example of packaging a gui application
#
include /usr/local/share/luggage/luggage.make

TITLE=example-firefox
REVERSE_DOMAIN=com.example.corp
TARBALL_LOCATION="http://tarball_host.example.com/tarballs/firefox-2010030901.tar.bz2"
PAYLOAD=unbz2-applications-Firefox.app
PACKAGE_VERSION=2010030901

# Having the tarball depend on Makefile ensures that make automatically
# downloads a new tarball when you update TARBALL_LOCATION, rather than
# building a stale payload.

Firefox.app.tar.bz2: Makefile
	curl ${TARBALL_LOCATION} -o Firefox.app.tar.bz2
