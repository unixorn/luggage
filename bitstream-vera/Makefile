#
#   Copyright 2011 Joe Block <jpb@ooyala.com>
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
# Wanted a nicer font for Terminal.
#
# Downloads bitsteam vera fonts and makes a package to install them.

include /usr/local/share/luggage/luggage.make

TITLE=bitstream-vera
REVERSE_DOMAIN=com.example.corp
PAYLOAD=bitstream_vera_fonts
FONT_D=${WORK_D}/Library/Fonts

TARBALL_LOCATION="http://ftp.gnome.org/pub/GNOME/sources/ttf-bitstream-vera/1.10/ttf-bitstream-vera-1.10.tar.bz2"

ttf-bitstream-vera-1.10.tar.bz2:
	curl ${TARBALL_LOCATION} -o ttf-bitstream-vera-1.10.tar.bz2

bitstream_vera_fonts:ttf-bitstream-vera-1.10.tar.bz2 l_Library_Fonts
	@sudo ${TAR} xjf ttf-bitstream-vera-1.10.tar.bz2 -C "${SCRATCH_D}"
	@sudo ${CP} ${SCRATCH_D}/ttf-bitstream-vera-1.10/*.ttf "${FONT_D}"
	@sudo rm -fr "${SCRATCH_D}/ttf-bitstream-vera-1.10"
	@sudo chown -R root:admin ${FONT_D}/*.ttf
