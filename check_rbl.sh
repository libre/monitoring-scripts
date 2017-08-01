#!/bin/bash
#
#    Program : check_rbl.sh
#            :
#     Author : Saïd <said@libre-cloud.org
#    Purpose : Nagios plugin to return Information from RBL Check
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
set -x
PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 2.0 $' | sed -e 's/[^0-9.]//g'`
file=`mktemp /tmp/statusrblcheck.XXXXX`

# Variable from Website :
URLRBLCHECK="http://rbl-check.org/rbl_api.php?ipaddress="
URLDNSPROOF="https://support.proofpoint.com/rbl-lookup.cgi?ip="

# Spoofing Agent Curl for Site check.
NAVAGENT=`echo -e "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0"`
CURL=`which curl `

# Testing Curl binary exist and parrsing option for script.
if [ -x /usr/bin/curl ] || [ -x /usr/local/bin/curl ] || [ -x /bin/curl ]; then
	# Parsing option for Curl -L for location redirection ex: http to redirect 301 to https
	CURLOPT=(-o ${file} -L -s -S -A "${NAVAGENT}")
else
	echo "UNKNOWN: Please check dep. curl not found."
	exit $STATUS_UNKNOW

fi

. $PROGPATH/utils.sh

print_usage() {
	echo "Usage: $PROGNAME [-H IPforcheck] [-a apicheckuse] [-w warning] [-c critical]"
	echo "          -H      Hostname (IP ONLY)"
	echo "          -a  apicheck : rblcheck, proofpoint"
	echo "          -w      (optional) warning threshold (default 1)"
	echo "          -c      (optional) critical threshold (default 2)"
	echo ""
	echo " rblcheck: http://rbl-check.org (Slow test ... Is big test RBL)"
	echo " proofpoint: http://upport.proofpoint.com (Veryfast) (default) "
	echo " "
	echo ""
	echo "Usage: $PROGNAME --help"
	echo "Usage: $PROGNAME --version"
}
print_help() {
	print_revision $PROGNAME $REVISION
	echo ""
	echo "Nagios plugin to return Information from RBL Check Website. API or not !"
	echo ""
	echo "Please, to use in moderation so that the webmaster change approach ..."
	echo "So, test by 24h and by IP is good. avoid 100 test every5min is not good!"
	echo ""
	print_usage
	echo ""
	echo "RBL Status Check. GPL http://github.com/libre/monitoring-scripts said@libre-cloud.org"
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
		-a)
			MODE=$2;
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

# Test value empty stop script
if [ "${REMOTEHOST}" = "" ]; then
	echo "UNKNOWN: Please check hostname"
	exit $STATUS_UNKNOW
fi
# Fonction valide IP
function valid_ip()
{
    local  ip=$REMOTEHOST
    local  stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}
# Test IP
if valid_ip $REMOTEHOST; then
        stat='good'
else
	# Stop not work bad IP
	stat='bad'
	echo "UNKNOWN: Please check ip "
	exit $STATUS_UNKNOW
fi
# Test value or default set
if [ "${MODE}" = "" ]; then
        MODE=proofpoint
fi
# Test value or default set
if [ "$WARNINGNUMBER" = "" ]; then
        WARNINGNUMBER=1
fi
# Test value or default set
if [ "$CRITICALNUMBER" = "" ]; then
        CRITICALNUMBER=2
fi
if [ "$MODE" = "rblcheck" ]; then
	# Rbl check mode
	# Get check status
	$CURL "${CURLOPT[@]}" "${URLRBLCHECK}${REMOTEHOST}"
	# Forms count values
	GETCHECKCOUNT=`cat $file | grep -w "listed" | awk 'END {print NR}'`
	TOTALCOUNTRBL1=`cat $file | awk 'END {print NR}'`
	# Final proccessing test result.
	if [ $GETCHECKCOUNT -lt $WARNINGNUMBER ]; then
			exitstatus=$STATU_OK
			MSG="OK: Not listed "
	elif [ $GETCHECKCOUNT -lt $CRITICALNUMBER ]; then
			exitstatus=$STATU_WARNING
			MSG="WARNING: ${GETCHECKCOUNT} List your IP is listed please look http://rbl-check.org/rbl_api.php?ipaddress=${REMOTEHOST}|count=${GETCHECKCOUNT}; ok=1"
	elif [ $GETCHECKCOUNT -ge $CRITICALNUMBER ]; then
			exitstatus=$STATU_CRITICAL
			MSG="CRITICAL: ${GETCHECKCOUNT} List your IP is listed VERY LISTEDBADSPAM please look http://rbl-check.org/rbl_api.php?ipaddress=${REMOTEHOST}|count=${GETCHECKCOUNT}; ok=1"
	else
			MSG="CRITICAL: Unknown command|count=0; ok=0"
	echo $MSG
	print_help
	exitstatus=$STATE_CRITICAL
	fi
elif [ "$MODE" = "proofpoint" ]; then
	# proofpoint mode
	# Get check status
	$CURL "${CURLOPT[@]}" "${URLDNSPROOF}${REMOTEHOST}"
	# Forms count values
	GETCHECKCOUNT2=`cat ${file} | grep "This IP Address is currently being blocked" | wc -l`
	if [ $GETCHECKCOUNT2 -eq 0 ]; then
			exitstatus=$STATU_OK
			MSG="OK: Not listed|count=0; ok=1"
	elif [ $GETCHECKCOUNT2 -eq 1 ]; then
			exitstatus=$STATE_CRITICAL
			MSG="WARNING: ${GETCHECKCOUNT} Your IP is listed on Diag RBL https://support.proofpoint.com|count=${GETCHECKCOUNT2}; ok=1"
	else
			MSG="CRITICAL: Unknown command|count=0; ok=0"
	echo $MSG
	print_help
	exitstatus=$STATE_CRITICAL
	fi
else
       MSG="CRITICAL: Unknown command|count=0; ok=0"
    echo $MSG
    print_help
    exitstatus=$STATE_CRITICAL
fi
rm -rf $file
echo $MSG
exit $exitstatus
