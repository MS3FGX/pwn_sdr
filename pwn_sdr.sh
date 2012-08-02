#!/bin/bash
# 
# PWN_SDR
VER="0.3"
#
# A script to install RTL-SDR on the Pwnie Express Pwn Plug. Can also start
# and stop rtl_tcp.

# Options
# Sample rate (lower this for slow network connections)
SRATE="1.5e6"

# Port to listen on
PORT="1234"

# Build DIR
BUILD_DIR="/tmp/sdr"

# Uncomment to run on non-Plugs. Safety is not guaranteed.
#UNPLUGGED="1"

#---------------------------------License--------------------------------------#
#
# Copyright 2012, Tom Nardi (MS3FGX@gmail.com)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#------------------------------------------------------------------------------#

ErrorMsg ()
{
# ErrorMsg  
# Displays either a minor (warning) or critical error, exiting on an critical.
# If message starts with "n", a newline is printed before message.
[[ $(expr substr "$2" 1 1) == "n" ]] && echo
if [ "$1" == "ERR" ]; then
	# This is a critical error, game over.
	echo "  ERROR: ${2#n}"
	exit 1
elif [ "$1" == "WRN" ]; then
	# This is only a warning, script continues but may not work fully.
	echo "  WARNING: ${2#n}"
fi
exit 1
}

InstallDEPS ()
{
echo -n "Updating Debian package list..."
apt-get update -qq || \
	ErrorMsg ERR "Unable to update packages!"
echo "OK"
echo "Installing dependencies..."
apt-get install -qq cmake git || \
	ErrorMsg ERR "Unable to install dependencies!"
echo "Dependencies installed."
}

RemoveDEPS ()
{
echo "Uninstalling dependencies..."
apt-get remove -qq git less libcurl3-gnutls liberror-perl \
	rsync cmake cmake-data emacsen-common libarchive1 \
	libcurl3 libxmlrpc-c3 || \
		ErrorMsg ERR "Unable to remove dependencies!"
echo "Dependencies uninstalled."
}

InstallSDR ()
{
echo -n "Creating build directory..."
# Delete any old build files, create new
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
echo "OK"
echo -n "Downloading RTL-SDR..."
cd $BUILD_DIR
git clone git://git.osmocom.org/rtl-sdr.git || \
	ErrorMsg ERR "Unable to download RTL-SDR!"
echo "OK"
echo "Building RTL-SDR..."
cd rtl-sdr/
mkdir build
cd build
cmake ../ || ErrorMsg ERR "Unable to configure RTL-SDR!"
make || ErrorMsg ERR "Unable to compile RTL-SDR!"
make install || ErrorMsg ERR "Unable to install RTL-SDR!"
echo "RTL-SDR installed."
echo -n "Updating shared libraries..."
ldconfig
echo "OK"
echo "------------------------------------------"
echo "RTL-SDR has been successfully installed!"
}

HardwareDiag ()
{
echo "Plug in your Realtek RTL2832U device and press any key to perform hardware"
echo "diagnostics, or press CTRL+C to skip."
read INPUT
rtl_test -t
}

RemoveSDR ()
{
echo -n "Removing RTL-SDR..."
rm /usr/local/lib/pkgconfig/librtlsdr.pc
rm /usr/local/include/rtl-sdr*
rm /usr/local/lib/librtlsdr.*
rm /usr/local/bin/rtl_*
echo "OK"
echo -n "Removing build directory..."
rm -rf $BUILD_DIR
echo "OK"
echo "RTL-SDR removed!"
}

Boiler ()
{
echo "  _____      ___  _   ___ ___  ___ "
echo " | _ \ \    / / \| | / __|   \| _ \ "
echo " |  _/\ \/\/ /| .\` | \__ \ |) |   / "
echo " |_|   \_/\_/ |_|\_| |___/___/|_|_\  "
echo
}

# Execution Start

# Few sanity checks
# Are we root? Should always be on Plug, but who knows.
if [[ $EUID -ne 0 ]]; then
   echo "PWN_SDR must be run as root!" 1>&2
   exit 1
fi

if [[ $UNPLUGGED -ne 1 ]]; then
	# Is this a Pwn Plug?
	grep "Pwn Plug" /etc/motd > /dev/null \
	 || ErrorMsg ERR "This script is only designed for the Pwnie Express Pwn Plug!"
fi

case $1 in
'install')
	Boiler
	echo "This will install RTL-SDR on your Pwn Plug."
	echo "Installation will take approximately 28 MB." 
	echo
	echo "Press CRTL+C to abort, any other key to continue."
	read INPUT
	echo "Installing..."
	InstallDEPS
	InstallSDR
	echo
	HardwareDiag
;;
'uninstall')
	echo "Are you sure you want to remove RTL-SDR and all build dependencies?"
	echo "Press CRTL+C to abort, any other key to continue."
	read INPUT
	RemoveDEPS
	RemoveSDR
;;	
'upgrade')
	echo "Upgrading RTL-SDR will compeltely remove your existing installation."
	echo "Are you sure you wish to continue?"
	echo
	echo "Press CRTL+C to abort, any other key to continue."
	read INPUT
	RemoveSDR
	InstallSDR
	echo
	HardwareDiag
;;
'start')
	IPADDR=`ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
	echo "Starting rtl_tcp on $IPADDR[$PORT]..."
	rtl_tcp -a $IPADDR -p $PORT -s $SRATE > /dev/null 2>&1 &
	exit 0
;;
'deps')
	Boiler
	echo "This will install the dependencies for RTL-SDR on your"
	echo "Pwn Plug. Installation will take approximately 24 MB." 
	echo
	echo "Press CRTL+C to abort, any other key to continue."
	read INPUT
	InstallDEPS
;;
'rmdeps')
	echo "This will remove all of the dependencies for RTL-SDR."
	echo "Approximately 24 MB will be freed."
	echo
	echo "Press CRTL+C to abort, any other key to continue."
	read INPUT
	RemoveDEPS
;;	
'stop')
	echo -n "Stopping rtl_tcp..."
	killall -9 rtl_tcp 2> /dev/null
	echo "OK!"
	exit 0
;;
'help')
	echo "This is PWN_SDR, a script to install RTL-SDR on the Pwnie Express Pwn Plug."
	echo
	echo "Beyond installing and removing RTL-SDR, it can also be used to start"
	echo "RTL-SDR's server, rtl_tcp, with known good settings."
	echo
	echo "The available arguments as of version $VER are as follows:"
	echo "install    - Install RTL-SDR"
	echo "uninstall  - Remove RTL-SDR"
	echo "upgrade    - Upgrade RTL-SDR"
	echo "deps       - Install dependencies"
	echo "rmdeps     - Remove dependencies"
	echo "start      - Starts rtl_tcp server"
	echo "stop       - Stops rtl_tcp server"
	echo "help       - What you are reading now"
;;
*)
	echo "PWN_SDR Version: $VER"
	echo "usage: $0 install|uninstall|upgrade|deps|rmdeps|start|stop|help"
esac
# EOF
