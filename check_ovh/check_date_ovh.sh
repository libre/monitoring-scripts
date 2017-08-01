#!/bin/bash
#set -x
#
#    Program : check_date_ovh.sh
#            :
#     Author : Deraoui Said     <sde@keysource.be>
#              Adel Iazzag      <aia@keysource.be>
#              Droubay Xavier   <xdr@keysource.be>
#    Purpose : Nagios plugin to return Information on domain expiration date from OVH API
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
REVISION=`echo '$Revision: 1.0.0.0 $' | sed -e 's/[^0-9.]//g'`

. $PROGPATH/utils.sh

date2stamp () {
    date --utc --date "$1" +%s
}

dateDiff (){
    case $1 in
        -s)   sec=1;      shift;;
        -m)   sec=60;     shift;;
        -h)   sec=3600;   shift;;
        -d)   sec=86400;  shift;;
        *)    sec=86400;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp $2)
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}

print_usage() {
        echo "Usage: $PROGNAME [-u userovh] [-p passwordovh] [-d domainforcheck] [-w warning] [-c critical]"
                echo "          -u user for OVH Manager API"
                echo "          -p password for OVH Manager API"
                echo "          -d domaine to check expiration date"
        echo "          -w      (optional) warning threshold (default 30 day)"
        echo "          -c      (optional) critical threshold (default 7 day)"
        echo ""
                echo "Usage: $PROGNAME --help"
        echo "Usage: $PROGNAME --version"
}
print_help() {
        print_revision $PROGNAME $REVISION
        echo ""
        echo "Nagios plugin to return Information on domain expiration date from OVH API"
        echo ""
        print_usage
        echo ""
        echo "OVH Expiration Check DNS. © Keysource 2013"
        echo ""
        exit 0
#        support
}
if [ ! -f "/usr/lib/nagios/plugins/apiovh.pl" ]
    then
                echo "apiovh.pl not exist please check file exist !"
                echo "Test stoped"
                exit $STATE_UNKNOWN
fi
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

                -u)
                    OUSER=$2;
                    shift;
                    ;;
                                -p)
                                        OPASSWORD=$2;
                                        shift;
                                        ;;
                                -d)
                                        ODOMAIN=$2;
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

# Test vide
if [ "${OUSER}" = "" ]; then
        echo "UNKNOWN: Please check User OVH"
        exit $STATE_UNKNOWN
fi
# Test vide
if [ "${OPASSWORD}" = "" ]; then
        echo "UNKNOWN: Please check Password OVH"
        exit $STATE_UNKNOWN
fi
# Test vide
if [ "${ODOMAIN}" = "" ]; then
        echo "UNKNOWN: Please check Domain for test"
        exit $STATE_UNKNOWN
fi

if [ "${MODE}" = "" ]; then
        MODE=dnsbls
fi
if [ "$WARNINGNUMBER" = "" ]; then
        WARNINGNUMBER=30
fi

if [ "$CRITICALNUMBER" = "" ]; then
        CRITICALNUMBER=7
fi

GETDATEXPIR=`/usr/lib/nagios/plugins/apiovh.pl $OUSER $OPASSWORD $ODOMAIN | grep expiration | awk '{print $3}' | sed -e "s/[',]//g"`
GETDATENOW=`date +"%Y-%m-%d"`
GETCOUNT=`dateDiff -d "$GETDATENOW" "$GETDATEXPIR"`

if   [ -z "$GETDATEXPIR"  ] || [ -n "`echo -ne "$GETDATEXPIR" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$//'`" ]; then
        exitstatus=$STATE_UNKNOWN
        MSG="ERROR: Cannot retrieve expiration date. Problem can be: i. Wrong Date Format; ii. Error with OVH Connection; iii. Domain ${ODOMAIN} Not Found."
elif [ $GETCOUNT -gt $WARNINGNUMBER ]; then
        exitstatus=$STATE_OK
        MSG="OK domain ${ODOMAIN} expires in ${GETCOUNT} days."
elif [ $GETCOUNT -gt $CRITICALNUMBER ]; then
        exitstatus=$STATE_WARNING
        MSG="WARNING: Domain ${ODOMAIN} expires in ${GETCOUNT} days !"
else
        exitstatus=$STATE_CRITICAL
        MSG="CRITICAL: Domain ${ODOMAIN} expires in ${GETCOUNT} days !"
                #print_help
fi

echo $MSG
exit $exitstatus
