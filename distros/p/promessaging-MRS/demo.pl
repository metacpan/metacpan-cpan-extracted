#!/usr/bin/perl -T

package main;

use promessaging::MRS;
use Data::Dumper;

if ($#ARGV==-1||$#ARGV!=3||$#ARGV>3)
{
print "\n";
print "Error, you didn't provide the correct number or order of parameters ... Execution aborted.\n\n";
print "You have to provide the following 4 parameters in the order demonstrated below.\n\n";
print "First, '-userid-' a valid account id, e.g. '12345'.\n";
print "Secondly, '-passwd-' a valid password for the given account id, e.g. 'mysecretpasswd'.\n";
print "Thirdly, '-profile-' a vaild profile number, e.g. '5'. Ask 'hotline\@end2endmobile.com' for your appropriate profile.\n";
print "Fourthly, '-msisdn-' a valid MSISDN in international format, e.g. '+441719876543'.\n\n";
}
else {

if (!($mrs_object = promessaging::MRS->new())) {
	print "Can't create MRS object.\n";
	exit;
}



# NB:	 MSISDNResolve() parameter info below

# -userid- = a valid account id, e.g. '12345'
# -passwd-    = a valid password for the given account, e.g. 'mysecretpasswd'
# 0        = a valid profile integer value (range from 0 to 7 - ask the hotline for your corresponding profile), e.g. '6' 
# -msisdn- = a valid MSISDN in international format, e.g. '+491710123456'


#my $result = $mrs_object->MSISDNResolve("-userid-", "-passwd-", 0, "-msisdn-");


my $result = $mrs_object->MSISDNResolve($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3]);


if ($result < 0) {
	print "error: " . $mrs_object->getError() . "\n";
} else {
	print Dumper($result) . "\n";
}

exit 0;

}