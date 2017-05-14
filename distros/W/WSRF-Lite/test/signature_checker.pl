#! /usr/bin/perl -w
#
# simple WSS perl client - creates a Signed SOAP message then
# checks the signature
#
# version 0.1
#

BEGIN {
  @INC = ( @INC, ".." );
};  


use strict;
use WSRF::Lite;
use Crypt::OpenSSL::RSA;

#Points to the public key of the X509 certificate
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
#Points to the provate key of the cert - must be unencrypted
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";
#Tells WSRF::Lite to sign the message with the above cert
$ENV{WSS_SIGN} = 'true';

# The following lines shows another apporach to setting the cert and key
# information.  $WSRF::WSS::priv_key and $WSRF::WSS::pub_key can point to
# the actual values for the $WSRF::WSS::priv_key and $WSRF::WSS::pub_key
# or as shown below they can point to subroutines that return the actual
# values
#
#$WSRF::WSS::priv_key = sub {
#   open  (PRIV , $ENV{HOME}."/.globus/userkey.pem") or die "Cannot open priv\n";
#    my $priv = join "", <PRIV>;
#   close PRIV;
#   Crypt::OpenSSL::RSA->new_private_key($priv);
#};
#
#$WSRF::WSS::pub_key = sub {
#    open(CERT, $ENV{HOME}."/.globus/usercert.pem") ||
#              die("Could not open certificate file ".$ENV{HOME}."/.globus/usercert.pem" );
#    my $start=0;
#    my $cert="";
#    while (<CERT>) {
#        if (!m/-----END CERTIFICATE-----/ && $start==1) {
#            $cert = $cert . $_;
#        }
#        if (/-----BEGIN CERTIFICATE-----/) {
#            $start=1;
#        }
#    }
#   close(CERT);
#    return $cert;
#};



# We create a WSRF Serializer and Deserializer - we will not
# be sending the message, just creating it and checking the 
# signature
my $de = WSRF::Deserializer->new();
my $s = WSRF::WSRFSerializer->new();

# Create a simple SOAP::Data object to be put in the
# SOAP envelope
my $d = SOAP::Data->name('GetAllGRIs')->value('')->uri("http://vermont.mvc.mcc.ac.uk/GRI");


# Create the SOAP message - $envelope is XML ready to be put
# into a HTTP message
my  $envelope = $s->freeform($d);

print ">>>>>>Envelope>>>>>\n$envelope\n<<<<<<Envelope<<<<<<\n\n\n";


# Now deserialize the message into a WSRF::SOM object - the 
# difference between SOAP::SOM and WSRF::SOM is that the WSRF::SOM
# holds a copy of the XML which will be need when doing the checking.
my $som = $de->deserialize($envelope);

# Verify the signature - this function will die if there is something
# wrong with the message, eg if the signature is incorrect. 
# verify does not check weither the X509 is valid, or if the 
# message has expired, or if the correct parts are signed.
my %results = WSRF::WSS::verify($som);



# These are the results - they should be checked to see 
# if they meet the policy of the service or cleint
die "Message NOT Signed\n" unless $results{Signed};

# The X509 certificate that signed the message
print "X509 certificate=>\n$results{X509}\n" if $results{X509};

# Print the set of things that have been signed - things that could
# be signed are: 
# Body  (from SOAP)
# To, Action, MessageID, From, ReplyTo, RelatesTo (from WS-Addressing)
# Timestamp and BinarySecurityToken  (from WS-Security)
foreach my $key ( keys %{$results{PartsSigned}} )
{
   print "\"$key\" of message is signed.\n";
}

#print the creation and expiration time of the message
print "Message Created at \"$results{Created}\".\n" if $results{Created};
print "Message Expires at \"$results{Expires}\".\n" if $results{Expires};
