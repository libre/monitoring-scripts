#!/bin/bash
#
#    Program : check_apc_pdu_load.sh
#            :
#     Author : Saïd <said@libre-cloud.org
#    Purpose : Nagios/Centreon/Icinga2 plugin to return Information from APC PDU Load status
#            :
# Parameters : --help
#            : --version
#            :
#    Returns : Standard Nagios status_* codes as defined in utils.sh
#            :
#    Licence : GPL
#
#      Notes : See --help for details
#============:==============================================================

PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 1.2 $' | sed -e 's/[^0-9.]//g'`


. $PROGPATH/utils.sh

print_usage() {
    echo "Usage: $PROGNAME [-H hostname] [-c communauty] [-w warning] [-c critical]"
	echo "		-H	Hostname"
	echo "		-C	Communauty"
	echo "		-w	(optional) warning threshold"
	echo "		-c	(optional) critical threshold"
	echo ""
	echo ""
	echo "Usage: $PROGNAME --help"
	echo "Usage: $PROGNAME --version"
}

print_help() {
	print_revision $PROGNAME $REVISION
	echo ""
	echo "Nagios Plugin to check PDU APC Load Amperes in all oulet"
	echo ""
	print_usage
	echo ""
	echo "PDU APC Load Status Check. GPL http://github.com/libre/monitoring-scripts"
	echo ""
	exit 0
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
		-C) COMMUNAUTY=$2;
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

if [ "${REMOTEHOST}" = "" ]; then
	echo "UNKNOWN: Please check hostname"
	exit $STATUS_UNKNOW
fi
if [ "${COMMUNAUTY}" = "" ]; then
	COMMUNAUTY=public
fi

if [ "$WARNINGNUMBER" = "" ]; then
	WARNINGNUMBER=10
fi

if [ "$CRITICALNUMBER" = "" ]; then
	CRITICALNUMBER=8
fi
LOAD=`snmpwalk -v2c -c ${COMMUNAUTY} ${REMOTEHOST} SNMPv2-SMI::enterprises.318.1.1.12.2.3.1.1.2.1 | awk '/Gauge32:/ {print $4}'`
if [ "$LOAD" = "" ]; then
		echo "UNKNOWN: Unable to get load from PDU|rta=0; ok=0\n"
		exit $STATUS_UNKNOWN
	fi

	if [ $LOAD -lt $WARNINGNUMBER ]; then
		exitstatus=$STATU_OK
		ULOAD=`echo "scale=2; ${LOAD}/10" | bc`
		MSG="OK: ${ULOAD} Amps of load|rta=${ULOAD}; ok=1\n"
	elif [ $LOAD -lt $CRITICALNUMBER ]; then
		exitstatus=$STATU_WARNING
		ULOAD=`echo "scale=2; ${LOAD}/10" | bc`
		MSG="WARNING: ${ULOAD} Amps of load PDU, please check.|rta=${ULOAD}; ok=1\n"
	elif [ $LOAD -ge $CRITICALNUMBER ]; then
		exitstatus=$STATU_CRITICAL
		ULOAD=`echo "scale=2; ${LOAD}/10" | bc`
		MSG="CRITICAL: ${ULOAD} Amps of load PDU.|rta=${ULOAD}; ok=1\n"
else
        echo="CRITICAL: Unknown command|rta=0; ok=0\n"
        print_help
        exitstatus=$STATE_CRITICAL
fi
echo $MSG
exit $exitstatus

