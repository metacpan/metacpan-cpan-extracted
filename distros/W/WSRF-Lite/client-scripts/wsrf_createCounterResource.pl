#! /usr/bin/env perl

#
# script to create a new WSRF Counter resource - makes
# a createCounterResource call to a Web Service - 
#

BEGIN {
       @INC = ( @INC, ".." );
};


use WSRF::Lite +trace =>  debug => sub {};
#use WSRF::Lite;

#need to point to users certificates - these are only used
#if https protocal is being used.
#$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
#$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
#$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";


# Tells WSRF::Lite to Sign the SOAP message
# Uses the X509 above, private key must be unencrypted
#$ENV{WSS_SIGN} = 'true';

if ( @ARGV != 2)
{
  print "  Script to create a new Counter WS-Resource\n\n";	
  print "Usage:\n wsrf_createCounterResource.pl URL URI\n\n";
  print "   URI is the namespace for the service\n";
  print "   URL is the endpoint of the service\n";  
  print "\neg.\n\n  wsrf_createCounterResource.pl http://localhost:50000/Session/Counter/Counter http://www.sve.man.ac.uk/Counter\n";
  print "\nor\n  wsrf_createCounterResource.pl http://localhost:50000/Session/CounterFactory/CounterFactory http://www.sve.man.ac.uk/CounterFactory\n";
  print "\nor\n  wsrf_createCounterResource.pl http://localhost:50000/MultiSession/Counter/Counter http://www.sve.man.ac.uk/Counter\n";

  exit;
}

#get the location of the service
$target = shift @ARGV;
#get the namespace of the service
$uri = shift @ARGV;


$ans=  WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target))                  #location of service
         -> createCounterResource();              #function + args to invoke


if ($ans->fault) {  die "ERROR: ".$ans->faultcode."\n  ".$ans->faultstring."\n"; }



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

#Check we got a WS-Address EndPoint back - note there
#is a chance that there will be a WS-Addressing EPR 
#in the SOAP Header, this is the <wsa:From> element
#telling us who sent this message - so we do our
#search relative to the Body of the message
my $address = $ans->match("//Body//{$WSRF::Constants::WSA}Address") ?
              $ans->valueof("//Body//{$WSRF::Constants::WSA}Address") :
	      die "ERROR: No EndpointReference returned\n";


    
#We should check for ReferenceParameters but it is unlikely
#that we will find any       
my ($RefParam);
if ( $ans->dataof('//Body//ReferenceParameters/*') )
{

  my $i=0;
  foreach my $a ($ans->dataof('//Body//ReferenceParameters/*'))
  {
     $i++;
     my $name  = $a->name();
     my $uri   = $a->uri();
     my $value = $a->value();
     $RefParam .= "<myns".$i.":".$name." xmlns:myns".$i."=\"".$uri."\">".$value."</myns".$i.":".$name.">";
  }
}

print "\n   Created WSRF service:\n";
if ( $RefParam )
{
  print "           ReferenceParameters = $RefParam\n";
}
print "           EndPoint = $address\n\n";


