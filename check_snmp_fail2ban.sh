#!/bin/bash
#
#    Program : check_snmp_fail2ban.sh
#            :
#     Author : Saïd <said@libre-cloud.org
#    Purpose : Nagios plugin to return Information from Fail2ban
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
REVISION=`echo '$Revision: 1.0.0.2 $' | sed -e 's/[^0-9.]//g'`


. $PROGPATH/utils.sh

print_usage() {
        echo "Usage: $PROGNAME [-H hostname] [-q query]  [-c communauty] [-w warning] [-c critical]"
		echo "      -H  Hostname"
		echo "		-q	Command to query"
        echo "		-w	(optional) warning threshold"
        echo "		-c	(optional) critical threshold"
	echo ""
	    echo "SupportedCommands:"
        echo "		active	(check fail2ban is active)"
        echo "		countdrop (check fail2ban count dropping - iptables)"
	echo ""
        echo "Usage: $PROGNAME --help"
        echo "Usage: $PROGNAME --version"
}
print_help() {
        print_revision $PROGNAME $REVISION
        echo ""
        echo "Nagios plugin to return Information from Fail2ban"
        echo ""
        print_usage
        echo ""
        echo "Fail2Ban SNMP Status Check. GPL http://github.com/libre/monitoring-scripts said@libre-cloud.org"
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
				-C) COMMUNAUTY=$2;
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
if [ "${COMMUNAUTY}" = "" ]; then
	COMMUNAUTY="public"
fi
if [ "${CHECK}" = "active" ]; then
	## Checking active chanels on Asterisk
	ACTIVE=`snmpwalk -v2c -c ${COMMUNAUTY} ${REMOTEHOST} UCD-SNMP-MIB::prErrorFlag.1 | awk '{ print $4}'`	
	if [ "$ACTIVE" = "" ]; then
		echo "UNKNOWN: Unable to get Fail2ban status"
		exit $STATUS_UNKNOWN
	fi
	if [ "$ACTIVE" = "0" ]; then
		exitstatus=$STATE_OK
        MSG="Ok :Fail2ban is running"
	fi
	if [ "$ACTIVE" = "1" ]; then
		exitstatus=$STATE_CRITICAL
        MSG="CRITICAL ! Fail2ban is not running"
	fi	
elif [ "${CHECK}" = "countdrop" ]; then
##WARNING
if [ "$WARNINGNUMBER" = "" ]; then
WARNINGNUMBER=5
fi
if [ "$CRITICALNUMBER" = "" ]; then
CRITICALNUMBER=10
fi
	##Working to Ubuntu / Debian server
	COUNTDROP=`snmpwalk -v2c -c ${COMMUNAUTY} ${REMOTEHOST} .1.3.6.1.4.1.2021.50.100.1 | awk '{ print $4}'`
	if [ "$COUNTDROP" = "" ]; then
		echo "UNKNOWN: Unable to get number of dropped host|rta=0; ok=0\n"
		exit $STATUS_UNKNOWN
	fi
	##Work to CentOS / RH
	if [ "$COUNTDROP" = "Such" ]; then
		COUNTDROP=`snmpwalk -v2c -c ${COMMUNAUTY} ${REMOTEHOST} UCD-SNMP-MIB::extResult.1 | awk '{ print $4}'`
	fi
        if [ $COUNTDROP -lt $WARNINGNUMBER ]; then
                exitstatus=$STATE_OK
                MSG="OK: ${COUNTDROP} host dropped|rta=${COUNTDROP}; ok=1\n"
        elif [ $COUNTDROP -lt $CRITICALNUMBER ]; then
                exitstatus=$STATE_WARNING
                MSG="WARNING: ${COUNTDROP} host dropped|rta=${COUNTDROP}; ok=1\n"
        elif [ $COUNTDROP -ge $CRITICALNUMBER ]; then
                exitstatus=$STATE_CRITICAL
                MSG="CRITICAL: ${COUNTDROP} host dropped|rta=${COUNTDROP}; ok=1\n"
        fi
else
        echo="CRITICAL: Unknown command"
        print_help
        exitstatus=$STATE_CRITICAL
fi

echo $MSG
exit $exitstatus
