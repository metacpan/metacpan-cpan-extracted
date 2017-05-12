#!/usr/bin/perl
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

use Test::More tests => 7;

my $SchemaNS = SCHEMA2001;

my $xml_xsd = <<__STOCKQUOTE_XSD;
<?xml version="1.0"?>
<schema targetNamespace="http://example.com/stockquote/schemas"
       xmlns="$SchemaNS">
       
    <element name="TradePriceRequest">
        <complexType>
            <all>
                <element name="tickerSymbol" type="string"/>
            </all>
        </complexType>
    </element>

    <element name="TradePrice">
        <complexType>
            <all>
                <element name="price" type="float"/>
            </all>
        </complexType>
    </element>
</schema>
__STOCKQUOTE_XSD

my $xml_wsdl = <<'__STOCKQUOTE_WSDL';
<?xml version="1.0"?>
<definitions name="StockQuote"
    targetNamespace="http://example.com/stockquote/definitions"
    xmlns:tns="http://example.com/stockquote/definitions"
    xmlns:xsd1="http://example.com/stockquote/schemas"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns="http://schemas.xmlsoap.org/wsdl/">

    <import namespace="http://example.com/stockquote/schemas"
        location="http://example.com/stockquote/stockquote.xsd"/>

    <message name="GetLastTradePriceInput">
        <part name="body" element="xsd1:TradePriceRequest"/>
    </message>

    <message name="GetLastTradePriceOutput">
        <part name="body" element="xsd1:TradePrice"/>
    </message>

    <portType name="StockQuotePortType">
        <operation name="GetLastTradePrice">
           <input message="tns:GetLastTradePriceInput"/>
           <output message="tns:GetLastTradePriceOutput"/>
        </operation>
    </portType>
</definitions>
__STOCKQUOTE_WSDL

my $servns    = 'http://example.com/stockquote/service';
my $servlocal = 'StockQuoteService';
my $servname  = "{$servns}$servlocal";

my $xml_service = <<'__STOCKQUOTESERVICE_WSDL';
<?xml version="1.0"?>
<definitions name="StockQuote"
    targetNamespace="http://example.com/stockquote/service"
    xmlns:tns="http://example.com/stockquote/service"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:defs="http://example.com/stockquote/definitions"
    xmlns="http://schemas.xmlsoap.org/wsdl/">

    <import namespace="http://example.com/stockquote/definitions"
        location="http://example.com/stockquote/stockquote.wsdl"/>

    <binding name="StockQuoteSoapBinding" type="defs:StockQuotePortType">
        <soap:binding style="document"
           transport="http://schemas.xmlsoap.org/soap/http"/>
        <operation name="GetLastTradePrice">
           <soap:operation soapAction="http://example.com/GetLastTradePrice"/>
           <input>
               <soap:body use="literal"/>
           </input>
           <output>
               <soap:body use="literal"/>
           </output>
        </operation>
    </binding>

    <service name="StockQuoteService">
        <documentation>My first service</documentation>
        <port name="StockQuotePort" binding="tns:StockQuoteSoapBinding">
           <soap:address location="http://example.com/stockquote"/>
        </port>
    </service>
</definitions>
__STOCKQUOTESERVICE_WSDL

###
### BEGIN OF TESTS
###

my $wsa  = XML::Compile::SOAP::WSA->new(version => '1.0');

my $wsdl = XML::Compile::WSDL11->new($xml_service);
$wsdl->importDefinitions($xml_xsd);
$wsdl->addWSDL($xml_wsdl);

my $op  = eval { $wsdl->operation('GetLastTradePrice') };
#print $op->explain($wsdl, PERL => 'INPUT', recurse => 1);

my $err = $@ || '';
ok(defined $op, 'existing operation');
is($@, '', 'no errors');

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
    <wsa:To xmlns:wsa="http://www.w3.org/2005/08/addressing">http://example.com/stockquote</wsa:To>
    <wsa:Action xmlns:wsa="http://www.w3.org/2005/08/addressing">http://example.com/GetLastTradePrice</wsa:Action>
    <wsa:MessageID xmlns:wsa="http://www.w3.org/2005/08/addressing">my-message</wsa:MessageID>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
     <xsd1:TradePriceRequest xmlns:xsd1="http://example.com/stockquote/schemas">
        <tickerSymbol>IBM</tickerSymbol>
     </xsd1:TradePriceRequest>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__EXPECTED

$server_answers = <<__ANSWER;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope
   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
   xmlns:x0="http://example.com/stockquote/schemas"
   xmlns:wsa="http://www.w3.org/2005/08/addressing">
  <SOAP-ENV:Header>
     <wsa:MessageID>the reply</wsa:MessageID>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
     <x0:TradePrice>
         <price>3.14</price>
     </x0:TradePrice>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__ANSWER

my $answer = $client->
  ( tickerSymbol  => 'IBM'
  , wsa_MessageID => "my-message"
  );
ok(defined $answer, 'got answer');

is_deeply($answer,
   { body =>  # body is the name of the part!
        {price => 3.14}
   , wsa_MessageID => 'the reply'
   }
  );
