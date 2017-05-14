#! /usr/bin/perl 

BEGIN {
       @INC = ( @INC, "../.." );
};

use strict;

#
# This script adds a WS-Resource to ServiceGroup - since
# the stuff that is used in the Add is so complex we hard
# code in this script rather thab try and take if of the 
# command line.
#
use WSRF::Lite +trace =>  debug => sub {};

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";


# Tells WSRF::Lite to Sign the SOAP message
# Uses the X509 above, private key must be unencrypted
#$ENV{WSS_SIGN} = 'true';

if ( @ARGV != 1)
{
  print "This script simply adds a dumy service to the ServiceGroup with dummy content.\n\n";
  print "Usage: wsrf_ServiceGroupAdd.pl URL \n\n";
  print "    URL is the EndPoint of the ServiceGroup\n";
  print "\n wsrf_ServiceGroupAdd.pl http://localhost:50000/Session/myServiceGroup/myServiceGroup/2345235463546\n";
  exit;
}

#get the location/endpoint of the service
my $target = shift @ARGV;


#the Add operation belongs to this namespace
my $uri = $WSRF::Constants::WSSG;


#This is the information we are going to add to the ServiceGroup -
#we hard code it here because it is pretty complex to try and
#take off the command line. The Add operation can take three things
#in the message - the EPR of the service you want to add, some 
#content (meta-data) about the Service you are adding and optionally
#a time for how long the Service should stay registered for.
#(In this example we do not set a lieftime for the entry) 
my $StuffToAdd = "<wssg:MemberEPR  xmlns:wssg=\"$WSRF::Constants::WSSG\" 
                                   xmlns:wsa=\"$WSRF::Constants::WSA\">
                   <wsa:EndpointReference>
                    <wsa:Address>http://localhost:50500/Session/ServiceGroup/ServiceGroup</wsa:Address>		   
		   </wsa:EndpointReference>
		  </wssg:MemberEPR>
		  <wssg:Content xmlns:wssg=\"".$WSRF::Constants::WSSG."\">
		  <mmk:foo xmlns:mmk=\"http://vermont.mvc.mcc.ac.uk/foo\">bar</mmk:foo></wssg:Content>";

#for simplicity we use raw xml to construct the message ;-)
my $data = SOAP::Data->value($StuffToAdd)->type('xml');


my $ans = WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target))         #location of service
	 -> proxy("$target")                             #location of service
         -> Add($data);                                     #function + args to invoke


#check if the ans has been signed
eval{
   # the WSRF::WSS::verify checks for a signature, if the message is not 
   # signed or not signed correctly verify will die. verify returns a 
   # hash containing the the X509 used to sign the message, the timestamp 
   # and the names of the elements used to sign the message  
   my %results = WSRF::WSS::verify($ans);

   # The X509 certificate that signed the message
   print "X509 certificate=>\n$results{X509}\n" if $results{X509};

   #print the name of each element that is signed
   foreach my $key ( keys %{$results{PartsSigned}} )
   {
     print "\"$key\" of message is signed.\n";
   }

   #print the creation and expiration time of the message
   print "Message Created at \"$results{Created}\".\n" if $results{Created};
   print "Message Expires at \"$results{Expires}\".\n" if $results{Expires}; 
};
if ($@) 
{ 
  print STDERR "WARNING: SOAP Message not signed.\nWARNING: $@\n"; 
}
	 
#The Add operation returns a WS-Address!! This EPR is of the ServiceGroupEntry
#that models the entry you have just created - destroy the ServiceGroupEntry
#and the entry will disappear from the ServiceGroup. You also control the lifetime
#of the entry using the ServiceGroupEntry - using SetTerminationTime on it.
if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

#Check we got a WS-Address EndPoint back - note there
#is a chance that there will be a WS-Addressing EPR 
#in the SOAP Header, this is the <wsa:From> element
#telling us who sent this message - so we do our
#search relative to the Body of the message
my $address = $ans->match("//Body//{$WSRF::Constants::WSA}Address") ?
              $ans->valueof("//Body//{$WSRF::Constants::WSA}Address") :
              die "CREATE ERROR:: No EndpointReference returned\n";

print "\n   Added a dummy service to the ServiceGroup.\n";	      
print "\n   The WS-Resource representing the new entry:\n";
print "         EndPoint  = $address\n";


print "\n";
