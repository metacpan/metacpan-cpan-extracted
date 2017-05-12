#! /usr/bin/perl 

BEGIN {
       @INC = ( @INC, "../.." );
};

use strict;
#
# script to creates a new ServiceGroup in WSRF::Lite - note
# since WS-ServiceGroup does not define an operation to
# create a new ServiceGroup this only works with the sample
# ServiceGroup service provided with WSRF::Lite though
# it provides a pretty good template 
#
# The Resource Identifier for the resource is returned in the
# SOAP Headers - this Resource Identifier needs to be included
# in the SOAP Headers for any other calls to use this
# ServiceGroup

use WSRF::Lite +trace =>  debug => sub {};
#use SOAP::Lite;

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
  print "Usage: wsrf_createServiceGroup.pl URL\n";
  print "   URL is the endpoint of the service\n";
  print "eg.\n wsrf_createServiceGroup.pl http://localhost:50000/Session/myServiceGroup/myServiceGroup\n";

  exit;
}

#get the location/endpoint of the service
my $target = shift @ARGV;

#get the namespace of the service - this is hard coded for the
#ServiceGroup sample service distributed with WSRF::Lite
my $uri = "http://www.sve.man.ac.uk/myServiceGroup";

#This is the operation to invoke - again it is hard coded
#for the sample ServiceGroup distributed with WSRF::Lite
my $func = "createServiceGroup";


my $ans=  WSRF::Lite
         -> uri($uri)
	 -> on_action( sub {sprintf '%s/%s', @_} )       #override the default SOAPAction to use a '/' instead of a '#'
         -> wsaddress(WSRF::WS_Address->new()->Address($target))         #location of service
         -> createServiceGroup();                                     #function + args to invoke



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
	 
if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

#Check we got a WS-Address EndPoint back - note there
#is a chance that there will be a WS-Addressing EPR 
#in the SOAP Header, this is the <wsa:From> element
#telling us who sent this message - so we do our
#search relative to the Body of the message
my $address = $ans->match("//Body//{$WSRF::Constants::WSA}Address") ?
              $ans->valueof("//Body//{$WSRF::Constants::WSA}Address") :
              die "CREATE ERROR:: No EndpointReference returned\n";



print "\n   Created WSRF ServiceGroup:\n";
print "           EndPoint            = $address\n";


print "\n";
