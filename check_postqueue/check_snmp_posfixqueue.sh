#!/bin/bash
#
#    Program : check_snmp_posfixqueue.sh
#            :
#     Author : Deraoui Saïd <said.deraoui@keysource.be>
#    Purpose : Nagios plugin to return Information from Queue Postfix by SNMP
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
REVISION=`echo '$Revision: 1.0.0.1 $' | sed -e 's/[^0-9.]//g'`


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
        echo "Nagios plugin to return Information from Queue Postfix by SNMP"
        echo ""
        print_usage
        echo ""
        echo "Postfix Queue Status Check. © Deraoui Said 2012"
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
	WARNINGNUMBER=100
fi

if [ "$CRITICALNUMBER" = "" ]; then
	CRITICALNUMBER=80
fi

LOAD=`snmpwalk -v1 -c ${COMMUNAUTY} ${REMOTEHOST} NET-SNMP-EXTEND-MIB::nsExtendOutLine | awk '{print $4}'`

if [ "$LOAD" = "" ]; then
		echo "UNKNOWN: Unable to get postfix queue ... Please check snmp service on your postfix server"
		exit $STATUS_UNKNOWN
	fi

	if [ $LOAD -lt $WARNINGNUMBER ]; then
		exitstatus=$STATU_OK
		MSG="OK: ${LOAD} mail on queue."
	elif [ $LOAD -lt $CRITICALNUMBER ]; then
		exitstatus=$STATU_WARNING
		MSG="WARNING: ${LOAD} mail on queue, please check for spam attacks ?"
	elif [ $LOAD -ge $CRITICALNUMBER ]; then
		exitstatus=$STATU_CRITICAL
		MSG="CRITICAL: ${LOAD} mail on queue is very large, check for spam attacks !"
else

        echo="CRITICAL: Unknown command"
        print_help
        exitstatus=$STATE_CRITICAL
fi

echo $MSG
exit $exitstatus