#!/usr/bin/env perl
# Test interpretation of WSDL one-way.

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

#use Data::Dumper;
#$Data::Dumper::Indent = 1;

use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Util       qw/SCHEMA2001/;
use XML::Compile::SOAP::Util qw/WSDL11 WSDL11SOAP SOAP11HTTP/;
use XML::Compile::Tester;
use XML::Compile::SOAP11;

use Test::More tests => 11;
use Test::Deep;

my $testNS     = 'http://any-ns';
my $schema2001 = SCHEMA2001;
my $wsdl11     = WSDL11;
my $wsdl11soap = WSDL11SOAP;
my $soap11http = SOAP11HTTP;

my $xml_wsdl = <<"__WSDL";
<?xml version="1.0"?>
<definitions name="one-way-test"
   targetNamespace="$testNS"
   xmlns:tns="$testNS"
   xmlns:soap="$wsdl11soap"
   xmlns="$wsdl11">

   <types>
     <schema targetNamespace="$testNS" xmlns:tns="$testNS"
       xmlns="$schema2001">
       <element name="Send" type="int" />
     </schema>
   </types>

   <message name="SendInput">
     <part name="body" element="tns:Send" />
   </message>

   <portType name="MySender">
     <operation name="doSend">
       <input message="tns:SendInput" />
     </operation>
   </portType>

   <binding name="SendBinding" type="tns:MySender">
     <soap:binding style="document" transport="$soap11http" />
     <operation name="doSend">
        <soap:operation soapAction="http://any-action" />
        <input><soap:body use="literal" /></input>
     </operation>
   </binding>

   <service name="MyService">
     <documentation>My second service</documentation>
     <port name="pleaseSend" binding="tns:SendBinding">
       <soap:address location="fake-location"/>
     </port>
   </service>
</definitions>
__WSDL

###
### BEGIN OF TESTS
###

my $wsdl = XML::Compile::WSDL11->new($xml_wsdl);

ok(defined $wsdl, "created object");
isa_ok($wsdl, 'XML::Compile::WSDL11');

my $op = eval { $wsdl->operation('doSend') };
my $err = $@ || '';
ok(defined $op, 'existing operation');
is($@, '', 'no errors');
isa_ok($op, 'XML::Compile::SOAP11::Operation');
is($op->kind, 'one-way');

sub fake_server($$)
{  my ($request, $trace) = @_;
   my $content = $request->decoded_content;
   compare_xml($content, <<__EXPECTED, 'fake server received');
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope
    xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Body>
     <tns:Send xmlns:tns="http://any-ns">42</tns:Send>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__EXPECTED

   HTTP::Response->new(202, 'accepted'
    , [ 'Content-Type' => 'text/plain' ], 'there is no body');
}

my $client = $op->compileClient(transport_hook => \&fake_server);
ok(defined $client, 'compiled client');
isa_ok($client, 'CODE');

my ($answer, $trace) = $client->(body => 42);
ok(defined $answer, 'got answer');
cmp_deeply($answer, {});
