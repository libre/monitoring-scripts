#!/bin/bash
#
#    Program : check_dnsns.sh
#            :
#     Author : Saïd <said@libre-cloud.org
#    Purpose : Centreon plugin to return Information from NS Record Check
#            :
# Parameters : --help
#            : --version
#            :
#    Returns : Standard Centreon status_* codes as defined in utils.sh
#            :
#    Licence : GPL
#
#      Notes : See --help for details
#============:==============================================================
set -x
PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`

. $PROGPATH/utils.sh

print_usage() {
	echo "Usage: $PROGNAME [-H domaine.org] [-n 8.8.8.8] [-r ns1.domaine.org]"
	echo "          -H      Hostname (IP ONLY)"
	echo "          -n  	Query DNS Server default is OpenDNS (only IP)"
	echo "					Google 	: 8.8.8.8 - 8.8.4.4"
	echo "					OpenDNS : 208.67.222.222 - 208.67.220.220"
	echo "          -r  	Query DNS Record NS"
	echo ""
	echo ""
	echo "Usage: $PROGNAME --help"
	echo "Usage: $PROGNAME --version"
}

print_help() {
	print_revision $PROGNAME $REVISION
	echo ""
	echo "Centreon plugin to return Information NS Record for domaine."
	echo ""
	echo ""
	print_usage
	echo ""
	echo "DNSNS Status Check. 2017 GPL http://github.com/libre/monitoring-scripts said@libre-cloud.org"
	echo ""
	exit 0
}
checkdep() {
	command -v dig >/dev/null 2>&1 || { echo "I require dig but it's not installed.  Aborting." >&2; exit $STATE_UNKNOWN; }
	command -v awk >/dev/null 2>&1 || { echo "I require awk but it's not installed.  Aborting." >&2; exit $STATE_UNKNOWN; }
	command -v wc >/dev/null 2>&1 || { echo "I require wc but it's not installed.  Aborting." >&2; exit $STATE_UNKNOWN; }
}

# If we have arguments, process them.
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
		-n)
			SRVDNS=$2;
			shift;
			;;
		-r)
			NSRECORD=$2
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
    local  ip=$SRVDNS
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

# Test value or default set
if [ "${SRVDNS}" = "" ]; then
        SRVDNS=208.67.222.222
fi
# Test NS SErver is IP
if valid_ip $SRVDNS; then
        stat='good'
else
	# Stop not work bad IP
	stat='bad'
	echo "UNKNOWN: Please check ip "
	exit $STATUS_UNKNOW
fi

# Test value NS Record query string ... 
# Not found, stop script. 
if [ "$NSRECORD" = "" ]; then
	echo "Not record found ! Please use help -r "
	exit $STATUS_UNKNOW
fi

checkdep

# Test Dig command query NS record on external server NS. 
GETCHECKCOUNT=`dig @$SRVDNS $REMOTEHOST NS | grep "NS" | awk '{ print $5 }' | grep $NSRECORD | wc -l`
# Final proccessing test result.
if [ $GETCHECKCOUNT -eq "1" ]; then
	exitstatus=$STATU_OK
	MSG="OK: NS record is $NSRECORD|ok=1\n"
else
	MSG="CRITICAL: Record $NSRECORD Not found !|ok=0\n"
	exitstatus=$STATE_CRITICAL
fi

echo $MSG
exit $exitstatus
