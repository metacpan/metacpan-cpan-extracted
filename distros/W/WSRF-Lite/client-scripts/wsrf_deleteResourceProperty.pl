#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, ".." );
};

use WSRF::Lite +trace =>  debug => sub {};
#use WSRF::Lite;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";


# Tells WSRF::Lite to Sign the SOAP message
# Uses the X509 above, private key must be unencrypted
#$ENV{WSS_SIGN} = 'true';

if ( @ARGV != 2 )
{
  print	"  Script to delete a ResourceProperty from a WS-Resource\n\n";
  print "Usage:\n wsrf_deleteResourceProperty.pl URL Property\n\n";
  print "     URL is the endpoint of the Web Service\n";
  print "     Property is the property to delete \n\n";
  print "wsrf_deleteResourceProperty.pl http://localhost:50000/MultiSession/Counter/Counter/19501981104038050279 foo\n";
  exit;
}


#get the location of the service
$target = shift @ARGV;

$param = shift @ARGV;

$deleteTerm = "<wsrp:Delete xmlns:wsrp=\"$WSRF::Constants::WSRP\" \
               resourceProperty=\"$param\"/>";

$ans=  WSRF::Lite
       -> uri($WSRF::Constants::WSRP)
       -> wsaddress(WSRF::WS_Address->new()->Address($target)) 
       -> SetResourceProperties( SOAP::Data->value($deleteTerm )->type( 'xml' ) );             #function + args to invoke

       
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
  print STDERR "WARNING: SOAP Message not signed.\nWARNING $@\n";
}

# check what we got back from the service - if it is a
# simple variable print it elsif it is a Reference to
# an ARRAY iterate through it and print the values
if ( $ans->fault)
{
  print "\nERROR: ".$ans->faultcode, " ", $ans->faultstring, "\n";
  exit;
}

   print "\n Deleted Property $param ".$ans->result."\n";

print "\n";
