#!/usr/bin/perl

$num_args = $#ARGV + 2;

$ouser=$ARGV[0];
$opassword=$ARGV[1];
$odomain=$ARGV[2];

if ($num_args != 3) {

use Data::Dumper;
use SOAP::Lite
 on_fault => sub { my($soap, $res) = @_; die ref $res ? $res->faultstring : $soap->transport->status; };

my $soap = SOAP::Lite
 -> uri('https://soapi.ovh.com/manager')
 -> proxy('https://www.ovh.com:1664');

#login
my $result = $soap->call( 'login' => ($ouser, $opassword, 'fr', 0) );
print "login successfull\n";
my $session = $result->result();

#domainCheck
my $result = $soap->call( 'domainInfo' => ($session, $odomain) );
print "domainCheck successfull\n";
my $return = $result->result();
print Dumper $return; # your code here ...

#logout
$soap->call( 'logout' => ( $session ) );
print "logout successfull\n";

exit;
}
else {
 print "Error please give me userovh passwordovh domaintest\n";
 print "exemple apiovh.pl gsuser-ovh password domaineforcheck.com\n";
 exit;
}
