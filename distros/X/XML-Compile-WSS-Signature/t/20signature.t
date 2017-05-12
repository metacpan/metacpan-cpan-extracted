#!/usr/bin/env perl
use warnings;
use strict;

use lib '../XMLWSS/lib', 'lib';

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::SOAP::WSS;
use XML::Compile::WSS::Util  qw/:dsig :xtp10/;
use XML::Compile::C14N::Util qw/:c14n/;

use Log::Report mode => 2;
use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
use Test::More;

BEGIN {
    eval "require Crypt::OpenSSL::RSA";
    $@ and plan skip_all => "Crypt::OpenSSL::RSA not installed";

    plan tests => 2;
}

require XML::Compile::WSS::SecToken::X509v3;

my $ns        = "http://example.net/";
my $wsdlfn    = 't/20any.wsdl';
my $anyop     = 'Test';

# Create self-signed certificate, from http://www.madboa.com/geek/openssl/
# openssl req -x509 -nodes -days 365 \
#  -subj '/C=NL/L=Arnhem/CN=example.com' \
#  -newkey rsa:1024 -keyout t/20privkey.pem -out t/20cert.pem

my $privkeyfn = 't/20privkey.pem';
my $certfn    = 't/20cert.pem';

# From http://publib.boulder.ibm.com/infocenter/cicsts/v3r1/index.jsp?topic=%2Fcom.ibm.cics.ts31.doc%2Fdfhws%2FwsSecurity%2Fdfhws_soapmsg_signed.htm
my $output_xml = 'example.xml';

my $wss  = XML::Compile::SOAP::WSS->new;
my $wsdl = XML::Compile::WSDL11->new($wsdlfn);

my $token =  XML::Compile::WSS::SecToken::X509v3->fromFile($certfn);
isa_ok($token, 'XML::Compile::WSS::SecToken::X509v3');

my $sig   = $wss->signature
  ( digest_method   => DSIG_SHA1          # default
  , signer          => DSIG_RSA_SHA1      # default
  , canon_method    => C14N_EXC_NO_COMM   # default
  , private_key     => $privkeyfn
  , token           => $token
  );

$wsdl->compileCalls(transport_hook => \&fake_server);
my ($out, $trace) = $wsdl->call($anyop, One => 1, Two => 2, Three => 3);
#warn "******* CALL END";
#warn Dumper $out;
$trace->printErrors;
#$trace->printResponse;
#my ($out2, $trace2) = $wsdl->call($anyop, One => 1, Two => 2, Three => 3);

ok(1, 'passed');
exit 0;

sub fake_server($$)
{  my ($request, $trace) = @_;
   my $content = $request->decoded_content;
   my $xml   = XML::LibXML->load_xml(string => $content);
#warn $xml->toString(1);

#warn "SENDING RESPONSE";
   HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/xml'], $content);
}
