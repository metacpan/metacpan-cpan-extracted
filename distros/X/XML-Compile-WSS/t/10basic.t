#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 7;

use XML::Compile::SOAP11;
use XML::Compile::WSDL11;
use XML::Compile::WSS::BasicAuth  ();
use XML::Compile::WSS::Util       qw/:wss11 :utp11/ ;

use XML::LibXML  ();

## How to get a relative path right??
my $wsdl = XML::Compile::WSDL11->new('t/example.wsdl') ;
ok($wsdl, 'created WSDL11');

my $wss  = XML::Compile::WSS::BasicAuth->new
  ( schema   => $wsdl
  , username => 'foo'
  , password => 'bar'
  , pwformat => UTP11_PDIGEST
  , created  => '2012-10-14T22:26:20Z'
  , nonce    => 'ABCD'
  );

ok($wss, 'created a WSS');
isa_ok($wss, 'XML::Compile::WSS::BasicAuth');

my $doc  = XML::LibXML::Document->new('1.0', 'UTF-8');
my $data = $wss->create($doc, {});
my ($type, $xml) = %$data;
isa_ok($xml, 'XML::LibXML::Element');

is($xml->toString(1)."\n", <<'__EXPECT');
<wsse:UsernameToken xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
  <wsse:Username>foo</wsse:Username>
  <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">QUJDRA==</wsse:Nonce>
  <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">vwmfO2G3ZB0hUC/MqV8n9hpr9JE=</wsse:Password>
  <wsu:Created ValueType="http://www.w3.org/2001/XMLSchema/dateTime">2012-10-14T22:26:20Z</wsu:Created>
</wsse:UsernameToken>
__EXPECT

my $wss2 = XML::Compile::WSS::BasicAuth->new
  ( schema   => $wsdl
  , username => 'foo'
  , password => 'bar'
  , pwformat => UTP11_PTEXT
  , created  => '2012-10-14T22:26:21Z'
  );

ok($wss2, 'created a WSS-2');
my $data2 = $wss2->create($doc, {});
my ($type2, $xml2) = %$data2;
is($xml2->toString(1)."\n", <<'__EXPECT');
<wsse:UsernameToken xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
  <wsse:Username>foo</wsse:Username>
  <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">bar</wsse:Password>
  <wsu:Created ValueType="http://www.w3.org/2001/XMLSchema/dateTime">2012-10-14T22:26:21Z</wsu:Created>
</wsse:UsernameToken>
__EXPECT

