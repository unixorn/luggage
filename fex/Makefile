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
# Package for Fex - The Flexible Token-Field Extractor
#   For more info on fex see http://github.com/jordansissel/fex
#
# Author: Gary Larizza
# Description: A simple installation of a binary to /usr/local/bin

include /usr/local/share/luggage/luggage.make

TITLE=Fex
REVERSE_DOMAIN=com.huronhs
PAYLOAD=pack-fex

pack-fex: l_usr_local_bin
	@sudo ${INSTALL} -m 755 ./fex ${WORK_D}/usr/local/bin