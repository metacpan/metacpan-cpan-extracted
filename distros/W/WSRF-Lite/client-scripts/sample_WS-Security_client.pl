#! /usr/bin/env perl -w
#
# simple WSS perl client
#
# version 0.1
#


#The include path must have WSRF::Lite in it
BEGIN {
       @INC = ( @INC, '..');
};       

use strict;
use WSRF::Lite +trace =>  debug => sub {};

#This is the public part of the X509
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
die "No X509 Public Key at \"$ENV{HTTPS_CERT_FILE}\"\n" 
             unless -r $ENV{HTTPS_CERT_FILE};  

#This is the private key - it must be un-encrypted
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";
die "No X509 Private Key at $ENV{HTTPS_KEY_FILE}\n"
             unless -r $ENV{HTTPS_KEY_FILE};

#Tells WSRF::Lite to Sign the SOAP message, really we should
#pass in some sort of Signing Policy object with details on
#how to sign the message....TODO
$ENV{WSS_SIGN} = 'true';

                     
#create a WS-Addressing object - Address is the endpoint of the service
my $wsa =  WSRF::WS_Address->new()->Address('http://wsgaf.ncl.ac.uk/services/registry/service/SecureResourceRegistry.asmx');

#Actually make the call - note we don't use proxy but wsaddress,
#we can use either or both! Note we use WSRF::Lite instead of
#SOAP::Lite
my $ans = WSRF::Lite->on_action( sub {'uk:ac:neresc:wsgaf:registry/GetAllGRIs'} )
		    ->wsaddress($wsa)
                    ->uri("urn:uk:ac:neresc:wsgaf:registry")
		    ->GetAllGRIs();
