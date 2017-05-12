#!/usr/bin/env perl
# Check whether the wsaAction is used for message selection.
# file.

use warnings;
use strict;

#use Data::Dumper;
#$Data::Dumper::Indent = 1;

#use Log::Report mode => 'DEBUG';

use XML::Compile::Util        qw/SCHEMA2001/;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Tester;
use Test::More;

eval "require Net::Server";
my $has_net_server = $@ ? 0 : 1;

eval "require LWP";
my $has_lwp = $@ ? 0 : 1;

plan skip_all => "Net::Server and LWP are need"
    unless $has_net_server && $has_lwp;

eval "require XML::Compile::SOAP::WSA";
$@ && plan skip_all => "XML::Compile::SOAP::WSA not installed";

eval "require XML::Compile::WSA::Util";
XML::Compile::WSA::Util->import(qw/WSDL11WSAW WSA10/);

plan tests => 10;
require_ok('XML::Compile::SOAP::Daemon::NetServer');

my $SchemaNS = SCHEMA2001;

# example from XMLWSA/t/30wsdl11.t
# http://www.w3.org/TR/2006/CR-ws-addr-wsdl-20060529/#explicitaction

my $ressvc = "http://greath.example.com/2004/schemas/resSvc";
my $types  = "urn:anything";
my $wsaw   = &WSDL11WSAW;
my $xsd    = SCHEMA2001;
my $wsans  = &WSA10;

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

my $wsa    = XML::Compile::SOAP::WSA->new(version => '1.0');
my $wsdl   = XML::Compile::WSDL11->new($xml_wsdl);

my $daemon = XML::Compile::SOAP::Daemon::NetServer->new
  ( accept_slow_select => 0
  );

$daemon->operationsFromWSDL($wsdl
  , callbacks =>
     { opCheckAvailability => sub () {
           my ($server, $data) = @_;
#use Data::Dumper;
#print STDERR Dumper \@_;
           is($data->{body}, 'ping');
#warn "CALLOP ", Dumper $data;
           +{body => 'yes', wsa_MessageID => 'the reply'}
         }
     }
  );

is_deeply  $daemon->addWsaTable('INPUT'),
  { opCheckAvailability
      => 'http://greath.example.com/2004/schemas/resSvc/opCheckAvailability'
  };

is_deeply  $daemon->addWsaTable('OUTPUT'),
  { opCheckAvailability
      => 'http://greath.example.com/2004/schemas/resSvc/opCheckAvailabilityResponse'
  };

### DAEMON simulation

my $expected_request;

# we avoid calling run(), but need this
$daemon->{wsa_input_rev}  = +{ reverse %{$daemon->{wsa_input}} };

sub fake_server($$)
{  my ($request, $trace) = @_;
   my $content = $request->decoded_content;
   compare_xml($content, $expected_request, 'fake server received');

   my ($rc, $msg, $answer) = $daemon->process(\$content, $request, undef);

#warn "($rc, $msg, ",$answer->toString(1),")";

   HTTP::Response->new($rc, $msg, [Content_Type => 'text/xml']
     , $answer->toString(1));
}

#
# create client
#

my $client = $wsdl->compileClient
  ( 'opCheckAvailability'
  , transport_hook => \&fake_server
  );

ok(defined $client, 'compiled client');
isa_ok($client, 'CODE');

$expected_request = <<__EXPECTED;
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

my $expected_answer = <<__ANSWER;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope
   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Header>
    <wsa:Action xmlns:wsa="http://www.w3.org/2005/08/addressing">http://greath.example.com/2004/schemas/resSvc/opCheckAvailabilityResponse</wsa:Action>
    <wsa:MessageID xmlns:wsa="http://www.w3.org/2005/08/addressing">the reply</wsa:MessageID>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <types:response xmlns:types="urn:anything">yes</types:response>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__ANSWER

my ($answer, $trace) = $client->(body => 'ping', wsa_MessageID => "my-message");
ok(defined $answer, 'got answer');

compare_xml($trace->response->content, $expected_answer);

is_deeply($answer,
   { body          => 'yes'
   , wsa_MessageID => 'the reply'
   , wsa_Action    => "$ressvc/opCheckAvailabilityResponse"
   }
  );
