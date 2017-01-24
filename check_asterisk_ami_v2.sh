#!/bin/bash
#
#    Program : check_asterisk_ami_v2.sh
#            :
#			 : base v1 : Jason Rivers 2011
#     Author : Deraoui Saïd <said@libre-cloud.org>
#      Notes : See --help for details
#
#============================================================

PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 1.1.0.6 $' | sed -e 's/[^0-9.]//g'`


. $PROGPATH/utils.sh

print_usage() {
        echo "Usage: $PROGNAME [-H hostname] [-q query] [-u username] [-p password] [-P port] [-w warning] [-c critical]"
	echo "		-H	Hostname"
        echo "		-q	Command to query"
        echo "		-u	AMI Username"
        echo "		-p	AMI Password"
        echo "		-P	(optional) AMI PORT"
        echo "		-w	(optional) warning threshold"
        echo "		-c	(optional) critical threshold"
	echo ""
        echo "SupportedCommands:"
        echo "			channels	(check number of current channels in-use)"
        echo "			calls		(check number of current calls)"
        echo "			sippeers	(check number of current calls)"
        echo "			iaxpeers	(check number of current calls)"
		echo "			checkpeer -n namepeer (check peer status)"
		echo "            for checkpeer -w -c is disabled"
		echo "			g729 (check number of current channels codec in-use)"
	echo ""
        echo "Usage: $PROGNAME --help"
        echo "Usage: $PROGNAME --version"
}

print_help() {
        print_revision $PROGNAME $REVISION
        echo ""
        echo "Nagios Plugin to check Asterisk using AMI"
        echo ""
        print_usage
        echo ""
        echo "Asterisk Call Status Check. - Jason Rivers 2011 and said@libre-cloud.org 2017"
		echo "GPL: URL http://github.com/libre/monitoring-scripts"
        echo ""
        exit 0
#        support
}

# If we have arguments, process them.
#
exitstatus=$STATE_WARNING #default
while test -n "$1"; do
        case "$1" in
                --help)
                        print_help
                        exit $STATE_OK
                        ;;
                -h)
                        print_help
                        exit $STATE_OK
                        ;;
                --version)
                        print_revision $PROGNAME $REVISION
                        exit $STATE_OK
                        ;;
                -V)
                        print_revision $PROGNAME $REVISION
                        exit $STATE_OK
                        ;;

                -H)
                    REMOTEHOST=$2;
                    shift;
                    ;;
                -P) AMIPORT=$2;
                    shift;
                    ;;
                -u) AMIUSER=$2;
                    shift;
                    ;;
                -p) AMIPASS=$2;
                    shift;
                    ;;
                -q) CHECK=$2;
                    shift;
                    ;;
				-n) NAME=$2;
					shift;
					;;
                -c)
                    CRITICALNUMBER=$2
                    shift;
                    ;;
                -w)
                    WARNINGNUMBER=$2;
                    shift;
                ;;

                *)
                        echo "Unknown argument: $1"
                        print_usage
                        exit $STATE_UNKNOWN
                        ;;
        esac
        shift
done
if [ "${AMIPORT}" = "" ]; then
	AMIPORT="5038"
fi

if [ "${CHECK}" = "channels" ]; then
##WARNING
if [ "$WARNINGNUMBER" = "" ]; then
	WARNINGNUMBER=10
fi
if [ "$CRITICALNUMBER" = "" ]; then
	CRITICALNUMBER=20
fi
## Checking active chanels on Asterisk
CHANNELS=`/bin/echo -e "Action: login\r\nUsername: ${AMIUSER}\r\nSecret: ${AMIPASS}\r\nEvents: off\r\n\r\nAction: CoreShowChannels\r\n\r\nAction: Logoff\r\n\r\n" | /bin/netcat $REMOTEHOST ${AMIPORT} | awk '/^ListItems/ {print $2}'|tr -d "\r"`
if [ "$CHANNELS" = "" ]; then
	echo "UNKNOWN: Unable to get number of Channels|channels=0; ok=0\n"
	exit $STATUS_UNKNOWN
fi

if [ $CHANNELS -lt $WARNINGNUMBER ]; then
	exitstatus=$STATU_OK
	MSG="OK: ${CHANNELS} Asterisk calls active|channels=${CHANNELS}; ok=1\n"
elif [ $CHANNELS -lt $CRITICALNUMBER ]; then
	exitstatus=$STATU_WARNING
	MSG="WARNING: ${CHANNELS} Asterisk calls active|channels=${CHANNELS}; ok=1\n"
elif [ $CHANNELS -ge $CRITICALNUMBER ]; then
	exitstatus=$STATU_CRITICAL
	MSG="CRITICAL: ${CHANNELS} Asterisk calls active|channels=${CHANNELS}; ok=1\n"
fi
elif [ "${CHECK}" = "calls" ]; then
	##WARNING
	if [ "$WARNINGNUMBER" = "" ]; then
		WARNINGNUMBER=5
	fi
	if [ "$CRITICALNUMBER" = "" ]; then
		CRITICALNUMBER=10
	fi
	CALLS=`/bin/echo -e "Action: login\r\nUsername: ${AMIUSER}\r\nSecret: ${AMIPASS}\r\nEvents: off\r\n\r\nAction: Command\r\ncommand: Core Show Channels\r\n\r\nAction: Logoff\r\n\r\n" | /bin/netcat ${REMOTEHOST} ${AMIPORT} | awk '/active call/ {print $1}' | tr -d "\r"`

	if [ "$CALLS" = "" ]; then
		echo "UNKNOWN: Unable to get number of calls|calls=0; ok=0\n"
		exit $STATUS_UNKNOWN
	fi

        if [ $CALLS -lt $WARNINGNUMBER ]; then
                exitstatus=$STATE_OK
                MSG="OK: ${CALLS} Asterisk calls active|calls=${CALLS}; ok=1\n"
        elif [ $CALLS -lt $CRITICALNUMBER ]; then
                exitstatus=$STATE_WARNING
                MSG="WARNING: ${CALLS} Asterisk calls active|calls=${CALLS}; ok=1\n"
        elif [ $CALLS -ge $CRITICALNUMBER ]; then
                exitstatus=$STATE_CRITICAL
                MSG="CRITICAL: ${CALLS} Asterisk calls active|calls=${CALLS}; ok=1\n"
        fi
	if [ "$CALLS" = "" ]; then
		CALLS=0
	fi
elif [ "${CHECK}" = "iaxpeers" ]; then
	##WARNING
	if [ "$WARNINGNUMBER" = "" ]; then
		WARNINGNUMBER=5
	fi
	if [ "$CRITICALNUMBER" = "" ]; then
		CRITICALNUMBER=10
	fi

	IAXpeers=`/bin/echo -e "Action: login\r\nUsername: ${AMIUSER}\r\nSecret: ${AMIPASS}\r\nEvents: off\r\n\r\nAction: Command\r\ncommand: iax2 show peers\r\n\r\nAction: Logoff\r\n\r\n" | /bin/netcat ${REMOTEHOST} ${AMIPORT} | awk '/online/ {print $0}' | tr -d "\r"`
	ONLINE=`echo $IAXpeers | sed 's/.*\[\(.*\) online.*unmonitored.*/\1/'`
	OFFLINE=`echo $IAXpeers | sed 's/.*online, \(.*\) offline.*unmonitored.*/\1/'`
	if [ "$OFFLINE" = "" ]; then
		echo "UNKNOWN: Unable to get number of IAX Peers|online=0 offline=0}; ok=0\n"
		exit $STATUS_UNKNOWN
	fi

        if [ $OFFLINE -lt $WARNINGNUMBER ]; then
                exitstatus=$STATE_OK
                MSG="OK: ${ONLINE} online, ${OFFLINE} offline IAX2 peers|online=${ONLINE} offline=${OFFLINE}; ok=1\n"
        elif [ $OFFLINE -lt $CRITICALNUMBER ]; then
                exitstatus=$STATE_WARNING
                MSG="WARNING: ${ONLINE} online, ${OFFLINE} offline IAX2 peers|online=${ONLINE} offline=${OFFLINE}; ok=1\n"
        elif [ $OFFLINE -ge $CRITICALNUMBER ]; then
                exitstatus=$STATE_CRITICAL
                MSG="CRITICAL: ${ONLINE} online, ${OFFLINE} offline IAX2 peers|online=${ONLINE} offline=${OFFLINE}; ok=1\n"
        fi

elif [ "${CHECK}" = "sippeers" ]; then

	##WARNING
	if [ "$WARNINGNUMBER" = "" ]; then
		WARNINGNUMBER=5
	fi
	if [ "$CRITICALNUMBER" = "" ]; then
		CRITICALNUMBER=10
	fi

	SIPpeers=`/bin/echo -e "Action: login\r\nUsername: ${AMIUSER}\r\nSecret: ${AMIPASS}\r\nEvents: off\r\n\r\nAction: Command\r\ncommand: sip show peers\r\n\r\nAction: Logoff\r\n\r\n" | /bin/netcat ${REMOTEHOST} ${AMIPORT} | awk '/online/ {print $0}' | tr -d "\r"`
	ONLINE=`echo $SIPpeers | sed 's/.*Monitored: \(.*\) online.*Unmonitored.*/\1/'`
	OFFLINE=`echo $SIPpeers | sed 's/.*online, \(.*\) offline.*Unmonitored.*/\1/'`

	if [ "$OFFLINE" = "" ]; then
		MSG="UNKNOWN: Unable to get number of SIP Peers|online=0 offline=0; ok=0\n"
		echo $MSG
		exit $STATUS_UNKNOWN
	fi

	if [ $OFFLINE -lt $WARNINGNUMBER ]; then
			exitstatus=$STATE_OK
			MSG="OK: ${ONLINE} online, ${OFFLINE} offline SIP peers|online=${ONLINE} offline=${OFFLINE}; ok=1\n"
	elif [ $OFFLINE -lt $CRITICALNUMBER ]; then
			exitstatus=$STATE_WARNING
			MSG="WARNING: ${ONLINE} online, ${OFFLINE} offline SIP peers|online=${ONLINE} offline=${OFFLINE}; ok=1\n"
	elif [ $OFFLINE -ge $CRITICALNUMBER ]; then
			exitstatus=$STATE_CRITICAL
			MSG="CRITICAL: ${ONLINE} online, ${OFFLINE} offline SIP peers|online=${ONLINE} offline=${OFFLINE}; ok=1\n"
	fi
## Add fonction by said.deraoui@keysource.be 2012
elif [ "${CHECK}" = "checkpeer" ]; then
	WARNINGNUMBER=1
	CRITICALNUMBER=3
	### Add Test for Peer name
	if [ "$NAME" = "" ]; then
		MSG="For peer status test please check name of peer ex: -q checkpeer -n mysippeername"
		echo $MSG
		exit $STATUS_UNKNOWN
	fi
	if [ "$AMIUSER" = "" ]; then
		AMIUSER=Admin
	fi
	if [ "$AMIPASS" = "" ]; then
		AMIPASS=amp111
	fi

	SIPpeer=`/bin/echo -e "Action: login\r\nUsername: ${AMIUSER}\r\nSecret: ${AMIPASS}\r\nEvents: off\r\n\r\nAction: Command\r\ncommand: sip show peer ${NAME}\r\n\r\nAction: Logoff\r\n\r\n" | /bin/netcat ${REMOTEHOST} ${AMIPORT} | awk '/Status/ {print $3}' | tr -d "\r"`

	if [ "$SIPpeer" = "" ]; then
		MSG="UNKNOWN: Unable to get status of SIP Peer"
		echo $MSG
		exit $STATUS_UNKNOWN
	fi
	if [ "$SIPpeer" == "OK" ]; then
		MSG="Peer status ${NAME} OK"
		exitstatus=$STATE_OK
		#MSG="0"
	elif [ "$SIPpeer" == "UNKNOWN" ]; then
		MSG="CRITICAL: Peer status ${NAME} UNKNOWN"
		exitstatus=$STATE_CRITICAL
		#MSG="3"
	elif [ "$SIPpeer" == "UNREACHABLE"  ]; then
		MSG="WARNING: Peer status ${NAME} UNREACHABLE"
		exitstatus=$STATE_WARNING
		#MSG="1"
	elif [ "$SIPpeer" == "Unmonitored" ]; then
		MSG="CRITICAL: Peer status ${NAME} Unmonitored please active monitored peer"
		exitstatus=$STATE_CRITICAL
	fi

	### Add Test G729 Licenses use. 
	elif [ "${CHECK}" = "g729" ]; then
	##WARNING
	if [ "$AMIUSER" = "" ]; then
		AMIUSER=Admin
	fi
	if [ "$AMIPASS" = "" ]; then
		AMIPASS=amp111
	fi

	MAXLICTEST=`/bin/echo -e "Action: login\r\nUsername: ${AMIUSER}\r\nSecret: ${AMIPASS}\r\nEvents: off\r\n\r\nAction: Command\r\ncommand: g729 show licenses\r\n\r\nAction: Logoff\r\n\r\n" | /bin/netcat ${REMOTEHOST} ${AMIPORT} | awk '/encoders/ {print $4}'`
	if [ "$CRITICALNUMBER" = "" ]; then
		CRITICALNUMBER=`echo $MAXLICTEST`
	fi
	if [ "$WARNINGNUMBER" == "" ]; then
		WARNINGNUMBER=$(($CRITICALNUMBER-1))
	fi

	ONUSE=`/bin/echo -e "Action: login\r\nUsername: ${AMIUSER}\r\nSecret: ${AMIPASS}\r\nEvents: off\r\n\r\nAction: Command\r\ncommand: g729 show licenses\r\n\r\nAction: Logoff\r\n\r\n" | /bin/netcat ${REMOTEHOST} ${AMIPORT} | awk '/encoders/ {print substr($1, 1,  match($1, "/") -1)}'`
	FREEFORUSE=$(($MAXLICTEST-$ONUSE))
	if [ "$FREEFORUSE" = "" ]; then
		echo "UNKNOWN: Unable to get number of channels free for use on G729 Codec... Please check install|channels=0; ok=0\n"
		exit $STATUS_UNKNOWN
	fi

	if [ $ONUSE -lt $WARNINGNUMBER ]; then
		exitstatus=$STATE_OK
		MSG="OK: ${ONUSE} channels on use of ${CRITICALNUMBER}|channels=${ONUSE}; ok=1\n"
	elif [ $ONUSE -lt $CRITICALNUMBER ]; then
		exitstatus=$STATE_WARNING
		MSG="WARNING: Maximum licenses use ${ONUSE} channels on use of ${CRITICALNUMBER}|channels=${ONUSE}; ok=1\n"
	elif [ $ONUSE -ge $CRITICALNUMBER ]; then
		exitstatus=$STATE_CRITICAL
		MSG="CRITICAL: ${ONUSE} channels on use of ${CRITICALNUMBER}|channels=${ONUSE}; ok=1\n"
	fi
else
	echo="CRITICAL: Unknown command"
	print_help
	exitstatus=$STATE_CRITICAL
fi

echo $MSG
exit $exitstatus
