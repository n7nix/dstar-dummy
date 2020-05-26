#!/bin/bash
#
# Install dummy repeater & ircDDBgateway for a radioless D-Star
#
# Edit these two configuration files
# ircDDBgateway config file is in /etc/opendv/ircddbgateway
# dummyreapeater config file is in $HOME/.Dummy\ Repeater
DEBUG=

scriptname="`basename $0`"

CALLSIGN="N0ONE"
SRC_DIR=$HOME/dev/github
TMP_DIR=$HOME/tmp

# Variables for editing config files
DUMMY_CFG_FILE=".Dummy Repeater"
IRCDDB_CFG_FILE="/etc/opendv/ircddbgateway"
DONGLE_DEV="/dev/ttyUSB0"
DONGLE_SPEED=460800
RPT1CALL="${CALLPAD}A"
RPT1LIST="${CALLPAD}C,${CALLPAD}A,"
RPT2CALL="${CALLPAD}G"
RPT2LIST="${RPT2CALL},"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_callsign

function get_callsign() {

    echo "get_callsign()"
    # Check if call sign var has already been set
    if [ "$CALLSIGN" == "N0ONE" ] ; then
        read -t 1 -n 10000 discard
        echo -n "Enter call sign, followed by [enter]:"
        read -ep ": " CALLSIGN
    fi
    echo "checking call sign: $CALLSIGN"
    # Validate callsign
    sizecallstr=${#CALLSIGN}

    if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
        echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
        exit 1
    fi

    # Convert callsign to upper case
    CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')

    dbgecho "Using CALL SIGN: $CALLSIGN"
}

# ===== function check_install

function check_install() {
    PKG_LIST="opendv ircddbgateway dstarrepeat dummyrepeat"
    echo
    echo " == Check installed required packages"
    for pkgname in $PKG_LIST ; do
        echo
        echo " === DEBUG: Checking for package name ${pkgname}*"
        dpkg -l "${pkgname}*"
        echo "Status: $?"
    done

    echo
    echo " == Check config files"
#    CFG_FILE_LIST="\"/home/$USER/.Dummy\ Repeater\" $HOME/$DUMMY_CFG_FILE $IRCDDB_CFG_FILE"
#    for filename in `echo "${CFG_FILE_LIST}"` ; do
    for filename in "$HOME/$DUMMY_CFG_FILE" "$IRCDDB_CFG_FILE" ; do
        echo "DEBUG checking file name: $filename"
        if [ ! -e "$filename" ] ; then
            echo "Config file: $filename does not exist"
        else
            file "$filename"
        fi
    done

    echo
    echo " == Check port forwarding"
    type -P dig &>/dev/null
    if [ "$?" -ne 0 ] ; then
        echo
        echo " == Installing dnsutils"
        echo
        sudo apt-get install -y -q dnsutils
    else
        echo "Found program: dig"
    fi

    external_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

    echo "External IP: $external_IP"

    PORTNUM_LIST="20001 30001 30051 30061 40000"
    for portnum in $PORTNUM_LIST ; do

        # This command never completes without -w option
#        nc -vu -w 2 $external_IP $portnum
        echo "Check port: $portnum, ret: $?"
    done

    echo
    echo " == Check ThumbDV serial port"
    ls /dev/ttyUSB*
}

# ===== function usage
function usage() {
    echo "Usage: $scriptname [-c][-v][-h]" >&2
    echo "   -c | --check     Verify installed packages, config files & port forwarding"
    echo "   -v | --verbose   display verbose messages"
    echo "   -h | --help      display this message"
    echo

}

# ===== main

if [ 1 -eq 0 ] ; then
    echo " == DEBUG: Check config files"

    for filename in "/home/$USER/.Dummy Repeater" "$HOME/$DUMMY_CFG_FILE" "$IRCDDB_CFG_FILE" ; do
        echo "DEBUG checking file name: $filename"
        file "$filename"
    done
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "*** Running as user: $(whoami) ***" 2>&1
fi

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -c|--check)
	 check_install
         exit 0
	 ;;
      -v|--verbose)
         verbose="true"
         DEBUG=1
         dbgecho "Debug set to on."
         ;;
      -h|--help)
         usage
	 exit 0
	 ;;
      *)
	echo "Unknown option: $key"
	usage
	exit 1
	;;
   esac
shift # past argument or value
done


echo "  == Get call sign"

get_callsign

# pad D-Star field to 7 characters
if (( ${#CALLSIGN} == 7 )) ; then
   echo "No padding required for Callsign -$CALLSIGN"
else
      whitespace=""
      singlewhitespace=" "
      whitelen=`expr 7 - ${#CALLSIGN}`
#      echo " -- whitelen $whitelen, callsign $CALLSIGN callsign len ${#CALLSIGN}"

      for ((i=0; i < $whitelen; i++)) ; do
        whitespace=$(echo -n "$whitespace$singlewhitespace")
      done;
      CALLPAD="$CALLSIGN$whitespace"
fi


echo
echo "  == Make a dummy config file"

# Does source directory exist?
if [ ! -d "$TMP_DIR" ] ; then
    mkdir -p $TMP_DIR
fi
cd $SRC_DIR

if [ ! -e "$DUMMY_CFG_FILE" ; then

    cat > "$DUMMY_CFG_FILE" <<EOT
callsign1=$CALLSIGN
callsign2=3000
readDevice=hw:2,0 USB Audio(USB PnP Sound Device)
writeDevice=hw:2,0 USB Audio(USB PnP Sound Device)
dongleType=2
dongleDevice=$DONGLE_DEV
dongleSpeed=$DONGLE_SPEED
dongleAddress=
donglePort=2460
gwyAddress=127.0.0.1
gwyPort=20010
localAddress=127.0.0.1
localPort=20011
interfaceType=
interfaceConfig=1
pttInvert=0
squelchInvert=0
timeout=180
msgText=DV3000 Pi AMBE
bleep=1
yourCall=REF053BL
yourList="       E,       I,N7JN   C,N7JN   V,N7JN  CL,N7JN  L,N7JN CL,N7JNL,REF005AL,REF005C ,REF005CL,REF029AL,REF029B,REF029BL,REF030CL,REF053B,REF053BL,"
rpt1Call=$RPT1CALL
rpt1List=$RPT1LIST
rpt2Call=$RPT2CALL
rpt2List=$RPT2LIST
windowX=
windowY=
EOT
fi

echo
echo "  == Get prototype ircDDBgateway config file"
# sudo cp ircddbgateway /etc/opendv/
#sudo curl -L -s -o /etc/opendv/ircddbgateway https://raw.githubusercontent.com/nwdigitalradio/udrc-tools/master/udrc-setup/ircddbgateway

# temporary until we can determine what needs to be edited
sudo curl -L -s -o /$HOME/tmp/ircddbgateway https://raw.githubusercontent.com/nwdigitalradio/udrc-tools/master/udrc-setup/ircddbgateway
# Edit ircddbgateway config file

# Install build requirements
sudo apt-get install -y -q git build-essential automake debhelper libwxgtk3.0-dev libasound2-dev libusb-1.0-0-dev wiringpi fakeroot dnsutils

# get source for ircDDBgateway & dummyrepeater

# Does source directory exist?
if [ ! -d "$SRC_DIR" ] ; then
    mkdir -p $SRC_DIR
fi
cd $SRC_DIR

# Ignore that the source might already be downloaded
git clone https://github.com/dl5di/OpenDV.git

cd OpenDV/ircDDBGateway/
num_cores=$(nproc --all)

# Build installable Debian packages

pkgname="ircDDBGateway"
echo
echo "   == Build package: $pkgname"
cd OpenDV/$pkgname
dpkg-buildpackage -b -uc -j$num_cores


pkgname="DstarRepeater"
echo
echo "  == Build package: $pkgname"
cd ../$pkgname
dpkg-buildpackage -b -uc -j$num_cores

pkgname="DummyRepeater"
echo
echo "  == Build package: $pkgname"
cd ../$pkgname
dpkg-buildpackage -b -uc -j$num_cores


echo
echo "  == Install packages"
cd ..

ls -al *.deb
echo
sudo dpkg -i opendev-base*.deb
sudo dpkg -i ircddbgateway*.deb
sudo dpkg -i dstarrepeater*.deb

#dpkg -i ircddbgatewayd_1.20160331-1_armhf.deb
#dpkg -i opendv-base_1.20160331-1_all.deb
#dpkg -i ircddbgatewayd_1.20160331-1_armhf.deb
#dpkg -i ircddbgateway_1.20160331-1_armhf.deb

# Determine if port forwarding is working

# Name	    Type	Start	End	Protocol	NAT	IP	Private Port
# DCS	  Port-Range	30051	30059	UDP	eth0.v1530	10.0.42.41
# D-Plus  Port-Range	20001	20009	TCP or UDP	eth0.v1530	10.0.42.41
# CCS	  Port-Range	30061	30065	UDP	eth0.v1530	10.0.42.41
# D-Voice Port-Remap	40000	40000	UDP	eth0.v1530	10.0.42.41	40000
# Dextra  Port-Range	30001	30007	UDP	eth0.v1530	10.0.42.41

externIP=$(dig +short myip.opendns.com @resolver1.opendns.com)

# To ultimately check your network for the forwarded port use netcat to
# connect to the port via your external IP:

# This command never completes without -w option
nc -vu -w 2 $externlIP 53

# You'll have to monitor the connections on the DNS server to watch for
# the netcat connection because netcat may incorrectly report that the
# connection was successful due to the stateless nature of UDP