#!/usr/bin/env perl
# Test Literal RPC
# Example contributed by Daniel Ruoso

use warnings;
use strict;

use lib 'lib','t';
use TestTools;
use Test::Deep   qw/cmp_deeply/;

#use Log::Report mode => 3;  # debugging

use Data::Dumper;
$Data::Dumper::Indent = 1;

use XML::Compile::WSDL11;
use XML::Compile::Tester;

use Test::More tests => 14;
use XML::LibXML;
use XML::Compile::SOAP::Util ':soap11';
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;

my $NS      = 'http://example.com/hello';
my $soapenv = SOAP11ENV;

my $schema = <<_SCHEMA;
<?xml version="1.0" encoding="UTF-8"?>
<wsdl:definitions
    xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:s="http://www.w3.org/2001/XMLSchema"
    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
    xmlns:hello="$NS"
    xmlns="$NS"
    targetNamespace="http://example.com/hello">

  <wsdl:types>
    <s:schema elementFormDefault="qualified" targetNamespace="http://example.com/hello">
      <s:element minOccurs="0" maxOccurs="1" name="who" type="s:string"/>
      <s:element minOccurs="0" maxOccurs="1" name="greeting" type="s:string"/>
    </s:schema>
  </wsdl:types>
  <wsdl:message name="AskGreeting">
    <wsdl:part name="who" element="hello:who"/>
    <wsdl:part name="greeting" element="hello:greeting"/>
  </wsdl:message>
  <wsdl:message name="GiveGreeting">
    <wsdl:part name="greeting" element="hello:greeting"/>
  </wsdl:message>
  <wsdl:portType name="Greeting">
    <wsdl:operation name="Greet">
      <wsdl:input message="hello:AskGreeting"/>
      <wsdl:output message="hello:GiveGreeting"/>
    </wsdl:operation>
    <wsdl:operation name="Shout">
      <wsdl:input message="hello:AskGreeting"/>
      <wsdl:output message="hello:GiveGreeting"/>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="Greeting" type="hello:Greeting">
    <soap:binding transport="http://schemas.xmlsoap.org/soap/http" style="rpc"/>
    <wsdl:operation name="Greet">
      <wsdl:input>
        <soap:body use="literal" namespace="$NS" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" namespace="$NS" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="Shout">
      <wsdl:input>
        <soap:body use="literal" namespace="$NS" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" namespace="$NS" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="GreetService">
    <wsdl:port name="Greet" binding="hello:Greeting">
      <soap:address location="http://localhost:3000/rpcliteral/"/>
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
_SCHEMA

### HELPER
my ($server_expects, $server_answers);
sub fake_server($$)
{  my ($request, $trace) = @_;
   my $content = $request->decoded_content;
   compare_xml($content, $server_expects, 'fake server received');

   HTTP::Response->new(200, 'answer manually created'
    , [ 'Content-Type' => 'text/xml' ], $server_answers);
}

#
# Create and interpret a message
#

my $soap = XML::Compile::SOAP11::Client->new;
isa_ok($soap, 'XML::Compile::SOAP11::Client');
isa_ok($soap, 'XML::Compile::SOAP11');

my $wsdl = XML::Compile::WSDL11->new($schema);
ok(defined $wsdl, "created object");
isa_ok($wsdl, 'XML::Compile::WSDL11');

#
# Element part
#

ok(1, "** using element");

my $eop = $wsdl->operation('Greet');
isa_ok($eop, 'XML::Compile::SOAP11::Operation');
is($eop->name, 'Greet');
is($eop->style, 'rpc');

my $er = $eop->compileClient(transport_hook => \&fake_server);
isa_ok($er, 'CODE');

$server_expects = <<_EXPECTS;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="$soapenv">
  <SOAP-ENV:Body>
   <hello:Greet xmlns:hello="$NS" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
     <hello:who xmlns:hello="$NS">World</hello:who>
     <hello:greeting xmlns:hello="$NS">Hello</hello:greeting>
   </hello:Greet>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
_EXPECTS

$server_answers = <<_ANSWER;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="$soapenv">
  <SOAP-ENV:Body>
    <hello:GreetResponse xmlns:hello="$NS">
      <hello:greeting>Hello, World!</hello:greeting>
    </hello:GreetResponse>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
_ANSWER

my %data = ( who => 'World', greeting => 'Hello' );

my $ea = $er->(\%data);
ok(defined $ea, 'got element answer');
my $g = $ea->{GreetResponse};
isa_ok($g, 'HASH');
cmp_ok(keys %$g, '==', 1);
is($g->{greeting}, 'Hello, World!');
