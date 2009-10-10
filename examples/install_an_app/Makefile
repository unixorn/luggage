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
# 
# Example of packaging a gui application

include /usr/local/share/luggage/luggage.make

TITLE=install_foo_app
REVERSE_DOMAIN=com.example.corp
PAYLOAD=unbz2-applications-foo.app

# Create a .tar.bz2 or .tar.gz of the application you want to install, and
# then use unXX-applications-foo.app to install into /Applications, or
# unXX-utilities-foo.app to install into Utilities (replace XX with bz2 or
# gz as appropriate for your tarball).
#
# Make sure you use Apple's tar to create the tarball so resource forks and
# metadata are preserved.
