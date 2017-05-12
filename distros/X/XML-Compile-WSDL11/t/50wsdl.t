#!/usr/bin/env perl
# Test interpretation of WSDL.
# The definitions are copied frm the the WSDL 1.1 technical report,
# available from http://www.w3.org/TR/wsdl/
# with bugfix:
#  -  <port name="StockQuotePort" binding="tns:StockQuoteBinding">
#  +  <port name="StockQuotePort" binding="tns:StockQuoteSoapBinding">

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::SOAP::Util  qw/WSDL11 SOAP11HTTP/;
use XML::Compile::Tester;
use XML::Compile::SOAP11;

use Test::More tests => 41;
use Test::Deep;

use Log::Report   'try';

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
my $servaddr  = 'http://example.com/stockquote';

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

my $wsdl = XML::Compile::WSDL11->new($xml_service);

ok(defined $wsdl, "created object");
isa_ok($wsdl, 'XML::Compile::WSDL11');
is($wsdl->findName('wsdl:'), WSDL11);

my @services = $wsdl->findDef('service');
cmp_ok(scalar(@services), '==', 1, 'find service list context');
is($services[0]->{name}, $servlocal);

my $s   = try { $wsdl->findDef(service => 'aap') };
my $err = $@->wasFatal->toString; $err =~ s! at t/80.*\n$!!;
ok(!defined $s, 'find non-existing service');

is($err, <<'__ERR');
error: no definition for `aap' as service, pick from:
    {http://example.com/stockquote/service}StockQuoteService
__ERR

$s = try { $wsdl->findDef(service => $servname) };
$err = $@->wasFatal;
ok(defined $s, "request existing service $servlocal");
is("$@", '', 'no errors');
ok(UNIVERSAL::isa($s, 'HASH'));

my $s2 = try { $wsdl->findDef('service') };
$err = $@->wasFatal;
ok(defined $s, "request only service, not by name");
is("$@", '', 'no errors');
cmp_ok($s, '==', $s2, 'twice same definition');
#warn Dumper $s;

is($wsdl->endPoint, $servaddr);
is($wsdl->endPoint(service => $servname), $servaddr);

$wsdl->importDefinitions($xml_xsd);
$wsdl->addWSDL($xml_wsdl);

my $op = try { $wsdl->operation('noot') };
$err = $@->wasFatal->toString; $err =~ s!\sat t/80.*\n$!\n!;
ok(!defined $op, "non-existing operation");
is($err, <<'__ERR');
error: no operation `noot' for portType {http://example.com/stockquote/definitions}StockQuotePortType, pick from
    GetLastTradePrice
__ERR

$op = try { $wsdl->operation('GetLastTradePrice') };
$err = $@->wasFatal || '';
ok(defined $op, 'existing operation');
is("$@", '', 'no errors');
isa_ok($op, 'XML::Compile::SOAP11::Operation');
is($op->kind, 'request-response');

#delete $op->{schemas};   # far too much to dump
#warn Dumper $op; exit 1;

#
# collect some basic facts
#

my @addrs = $op->endPoints;
cmp_ok(scalar @addrs, '==', 1, 'get endpoint address');
is($addrs[0], 'http://example.com/stockquote');

my $http1 = 'http://schemas.xmlsoap.org/soap/http';

is($op->action, 'http://example.com/GetLastTradePrice', 'action');
is($op->style, 'document');
is($op->transport, SOAP11HTTP);

#
# test $wsdl->operations
#

my @ops = $wsdl->operations; #(server_type => 'BEA');
cmp_ok(scalar @ops, '==', 1, 'one op hash listed');
$op = shift @ops;

isa_ok($op, 'XML::Compile::SOAP::Operation');
isa_ok($op, 'XML::Compile::SOAP11::Operation');

is($op->name, 'GetLastTradePrice', 'got name');
is($op->action, 'http://example.com/GetLastTradePrice', 'got action');

is($op->serviceName, 'StockQuoteService');
is($op->bindingName, 'StockQuoteSoapBinding');
is($op->portName,    'StockQuotePort');
is($op->portTypeName, 'StockQuotePortType');

#
# test $wsdl->printIndex
#

my $x = '';
open my($out), '>', \$x;
$wsdl->printIndex($out);
close $out;
is($x, <<_INDEX);
service StockQuoteService
    SOAP11 port StockQuotePort (binding StockQuoteSoapBinding)
        GetLastTradePrice
_INDEX

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
   xmlns:x0="http://example.com/stockquote/schemas">
  <SOAP-ENV:Body>
     <x0:TradePrice>
         <price>3.14</price>
     </x0:TradePrice>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__ANSWER

my $answer = $client->(tickerSymbol => 'IBM');
ok(defined $answer, 'got answer');
cmp_deeply($answer, {body => {price => 3.14}});  # body is the name of the part

#
### check parsedWSDL
#
use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;

#print Dumper $op->parsedWSDL;

