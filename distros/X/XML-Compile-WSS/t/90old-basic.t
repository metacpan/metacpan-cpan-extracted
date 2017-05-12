#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 3;

use XML::Compile::SOAP11;
use XML::Compile::WSDL11;
use XML::Compile::SOAP::WSS ;
use XML::Compile::WSS::Util qw/:wss11 :utp11/ ;

## How to get a relative path right??
my $wsdl = XML::Compile::WSDL11->new('t/example.wsdl') ;
my $wss  = XML::Compile::SOAP::WSS->new( version => 1.1, schema => $wsdl);
ok($wss, 'Created a WSS object');
my $sec  = $wss->wsseBasicAuth( 'foo', 'bar', UTP11_PDIGEST);
ok($sec, '#PasswordDigest returns something sensible');
my ($type, $xml) = %$sec;
isa_ok($xml, 'XML::LibXML::Element');
#warn $xml->toString(1);
