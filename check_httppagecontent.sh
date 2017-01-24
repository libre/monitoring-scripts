#!/bin/bash
#
#    Program : check_httppagecontent.sh
#            :
#     Author : Saïd <said@libre-cloud.org
#    Purpose : Nagios plugin to return Information from Webpage 
#			 : Return value is prensent and time of load page. 
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
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`


# Testing Curl binary exist
if [ -x /usr/bin/curl ] || [ -x /usr/local/bin/curl ] || [ -x /bin/curl ]; then
        # Parsing option for Curl -L for location redirection ex: http to redirect 301 to https
        CURL="curl -S -s -L"
else
        echo "UNKNOWN: Please check dep. curl not found."
        exit $STATUS_UNKNOW

fi


. $PROGPATH/utils.sh

print_usage() {
        echo "Usage: $PROGNAME [-url hostname] [-uri communauty] [-string textstring] [-w warning] [-c critical]"
		echo "		-url hostname http or ex: https://github.com"
        echo "		-uri ex: personal (optional)"
        echo "		-string ex: fluidicon.png"
		echo ""
		echo "exemple: ./$PROGNAME -url https://github.com -uri personal -string fluidicon.png -w 1500 -c 2000"
		echo ""
        echo "		-w	(optional) warning threshold in milliseconde default 2500 - 2.5sec"
        echo "		-c	(optional) critical threshold in milliseconde default 5000 -  5sec"
	echo ""
	echo ""
        echo "Usage: $PROGNAME --help"
        echo "Usage: $PROGNAME --version"
}

print_help() {
        print_revision $PROGNAME $REVISION
        echo ""
        echo "Centreon/Nagios plugin to return Information from Webpage"
        echo "Return status and load page value for perf graph."
		echo ""		
        print_usage
        echo ""
        echo "Check loading page Status Check. http://github.com/libre/monitoring-scripts - said@libre-cloud.org 2017"
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
		-url)
			URL=$2;
			shift;
			;;
		-uri)
			URI=$2;
			shift;
			;;
		-string)
			STRING=$2;
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
# Test value URL is empty
if [ -z "${URL}" ]; then
	echo "UNKNOWN: Please check URL"
	exit $STATUS_UNKNOW
fi
# Test value URL content first HTTP not present add default HTTP
if echo $URL | grep -vq "^http" ; then
	URL="http://$URL"
fi
# Test value URI is empty
if [ -z "${URI}" ]; then
	URI=""
fi
#Full parsing
FULLURL="$URL/$URI"
if [ -z "${STRING}" ]; then
	echo "UNKNOWN: Please check String"
	exit $STATUS_UNKNOW
fi
# Default value warrning. 
if [ "$WARNINGNUMBER" = "" ]; then
	WARNINGNUMBER=2500
fi
# Default value critical
if [ "$CRITICALNUMBER" = "" ]; then
	CRITICALNUMBER=5000
fi
# Test string is present in content. 
CHECKCONTENT=`$CURL ${FULLURL} | grep "${STRING}" | wc -l`
# String not found stop script.
if [ $CHECKCONTENT == "0" ]; then
	exitstatus=$STATU_CRITICAL
	MSG="Erro: String not found in page !!|time=0ms; ok=0\n"
	echo $MSG
	exit $exitstatus
# String is found secondary test for loading page value. 
else
	#In bash only integer value, simple calcule... 
	CHECKLOADINDPAGE=`{ time $CURL ${FULLURL} >/dev/null; } 2>&1 | grep real | awk '{ print $2 }' | cut -dm -f2- | sed s'/.$//'`
	CHECKLOADINDPAGE=`echo "$CHECKLOADINDPAGE*1000" | bc -l | awk -F'.' '{print $1}'`
	if [ $CHECKLOADINDPAGE -lt $WARNINGNUMBER ]; then
		exitstatus=$STATU_OK
		# For print result on ms, inverse caclule... 
		CHECKLOADINDPAGE=`printf "%.3f\n" $(echo "secale=3; $CHECKLOADINDPAGE / 1000" | bc -l)`
		MSG="OK: Page Loaded to ${CHECKLOADINDPAGE} sec. |time=${CHECKLOADINDPAGE}ms; ok=1\n"
	elif [ $CHECKLOADINDPAGE -lt $CRITICALNUMBER ]; then
		exitstatus=$STATU_WARNING
		CHECKLOADINDPAGE=`printf "%.3f\n" $(echo "secale=3; $CHECKLOADINDPAGE / 1000" | bc -l)`
		MSG="WARNING: Page Loaded to ${CHECKLOADINDPAGE}sec. |time=${CHECKLOADINDPAGE}ms; ok=1\n"
	elif [ $CHECKLOADINDPAGE -ge $CRITICALNUMBER ]; then
		exitstatus=$STATU_CRITICAL
		CHECKLOADINDPAGE=`printf "%.3f\n" $(echo "secale=3; $CHECKLOADINDPAGE / 1000" | bc -l)`
		MSG="CRITICAL: Page Loaded to ${CHECKLOADINDPAGE}sec. |time=${CHECKLOADINDPAGE}ms; ok=1\n"
	fi
fi 
echo $MSG
exit $exitstatus