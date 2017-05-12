#!/usr/bin/perl
# Check whether the wsaAction is correctly taken from the WSDL11
# file.

use warnings;
use strict;

use lib 'lib','t';
#use TestTools;

use Data::Dumper;
$Data::Dumper::Indent = 1;

#use Log::Report mode => 'DEBUG';

use XML::Compile::Util        qw/SCHEMA2001/;
use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::SOAP::Util  qw/WSDL11 SOAP11HTTP/;
use XML::Compile::Tester;
use XML::Compile::SOAP11;
use XML::Compile::SOAP::WSA;
use XML::Compile::SOAP::WSA::Util qw/WSDL11WSAW WSA10/;

use Test::More tests => 9;

my $SchemaNS = SCHEMA2001;

# example from
# http://www.w3.org/TR/2006/CR-ws-addr-wsdl-20060529/#explicitaction

my $ressvc = "http://greath.example.com/2004/schemas/resSvc";
my $types  = "urn:anything";
my $wsaw   = WSDL11WSAW;
my $xsd    = SCHEMA2001;
my $wsans  = WSA10;

my $xml_wsdl = <<__WSDL;
<?xml version="1.0"?>
<definitions
  targetNamespace="$ressvc"
  xmlns:tns="$ressvc"
  xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
  xmlns:types="$types"
  xmlns:wsaw="$wsaw"
  xmlns="http://schemas.xmlsoap.org/wsdl/">

  <xs:schema xmlns:xs="$xsd"
    targetNamespace="$types">
    <xs:element name="request"  type="xs:string"/>
    <xs:element name="response" type="xs:string"/>
  </xs:schema>

  <message name="checkAvailability">
    <part name="body" element="types:request"/>
  </message>

  <message name="checkAvailabilityResponse">
    <part name="body" element="types:response"/>
  </message>
    
  <portType name="reservationInterface">
    <operation name="opCheckAvailability">
      <input message="tns:checkAvailability"
         wsaw:Action="$ressvc/opCheckAvailability"/>
      <output message="tns:checkAvailabilityResponse"
         wsaw:Action="$ressvc/opCheckAvailabilityResponse"/>
    </operation>
  </portType>

  <binding name="reservationBinding" type="tns:reservationInterface">
    <soap:binding style="document"
       transport="http://schemas.xmlsoap.org/soap/http"/>
    <operation name="opCheckAvailability">
      <soap:operation soapAction="$ressvc/CheckAvailability"/>
      <input><soap:body use="literal"/></input>
      <output><soap:body use="literal"/></output>
    </operation>
  </binding>

  <service name="reservations">
    <port name="reservation" binding="tns:reservationBinding">
      <soap:address location="http://localhost/aap/" />
    </port>
  </service>
</definitions>
__WSDL

###
### BEGIN OF TESTS
###

my $wsa  = XML::Compile::SOAP::WSA->new(version => '1.0');
my $wsdl = XML::Compile::WSDL11->new($xml_wsdl);

my $op  = eval { $wsdl->operation('opCheckAvailability') };
my $err = $@ || '';
ok(defined $op, 'existing operation');
is($@, '', 'no errors');

is($op->wsaAction('INPUT'), "$ressvc/opCheckAvailability");
is($op->wsaAction('OUTPUT'), "$ressvc/opCheckAvailabilityResponse");

### HELPER

my ($server_expects, $server_answers);
sub fake_server($$)
{  my ($request, $trace) = @_;
   my $content = $request->decoded_content;
#warn $content;
   compare_xml($content, $server_expects, 'fake server received');

   HTTP::Response->new(200, 'answer manually created'
    , [ 'Content-Type' => 'text/xml' ], $server_answers);
}

#
# create client
#

my $client = $op->compileClient
  ( transport_hook => \&fake_server
  , sloppy_floats  => 1
  );

ok(defined $client, 'compiled client');
isa_ok($client, 'CODE');

$server_expects = <<__EXPECTED;
<?xml version="1.0" encoding="UTF-8"?>
  <SOAP-ENV:Envelope
     xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
    <SOAP-ENV:Header>
      <wsa:To xmlns:wsa="$wsans">http://localhost/aap/</wsa:To>
      <wsa:Action xmlns:wsa="$wsans">$ressvc/opCheckAvailability</wsa:Action>
      <wsa:MessageID xmlns:wsa="$wsans">my-message</wsa:MessageID>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body>
      <types:request xmlns:types="urn:anything">ping</types:request>
    </SOAP-ENV:Body>
  </SOAP-ENV:Envelope>
__EXPECTED

$server_answers = <<__ANSWER;
<?xml version="1.0" encoding="UTF-8"?>
  <SOAP-ENV:Envelope
     xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
    <SOAP-ENV:Header>
      <wsa:Action xmlns:wsa="$wsans">$ressvc/opCheckAvailabilityResponse</wsa:Action>
      <wsa:MessageID xmlns:wsa="$wsans">the reply</wsa:MessageID>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body>
      <types:response xmlns:types="urn:anything">pong</types:response>
    </SOAP-ENV:Body>
  </SOAP-ENV:Envelope>
__ANSWER

my $answer = $client->(body => 'ping', wsa_MessageID => "my-message");
ok(defined $answer, 'got answer');

is_deeply($answer,
   { body          => 'pong'
   , wsa_MessageID => 'the reply'
   , wsa_Action    => "$ressvc/opCheckAvailabilityResponse"
   }
  );
