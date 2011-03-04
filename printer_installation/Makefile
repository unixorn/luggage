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
# Example: Printer Creation Example
# Author: Gary Larizza
# Description: This package will use a preflight script to setup the actual printer
#				and then dump a pre-created .ppd file into the appropriate directory
#				to set all the printer settings.  This worked much better than lpadmin
#				commands for me (and was easier).  Note that you could also copy over
#				custom printer definition files if they aren't pre-installed with OS X.

include /usr/local/share/luggage/luggage.make

TITLE=HHS_Main_Office_9040_Managed_Installer
REVERSE_DOMAIN=com.huronhs
PAYLOAD=\
		pack-hp-ppd \
		pack-script-preflight
		
# A preflight script (named 'preflight') sets up the printer, and the .ppd file copied in the next step
#   will customize your settings.  To create this package, first customize the preflight script and 
#   then customize your printer with whatever settings you need.  The custom .ppd file located in 
#   /etc/cups/ppd/ and should be copied to your working directory.  Change the .ppd filename
#   to match your printer name (from the preflight script) and you should be fine.

pack-hp-ppd: l_etc_cups_ppd
	@sudo ${CP} ./psm_HHS_Office_9040.ppd ${WORK_D}/etc/cups/ppd/psm_HHS_Office_9040.ppd
	@sudo chmod 644 ${WORK_D}/etc/cups/ppd/psm_HHS_Office_9040.ppd
	@sudo chown root:_lp ${WORK_D}/etc/cups/ppd/psm_HHS_Office_9040.ppd