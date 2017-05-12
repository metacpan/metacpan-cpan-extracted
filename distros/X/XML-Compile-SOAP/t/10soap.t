#!/usr/bin/env perl
# Test SOAP

use warnings;
use strict;

use lib 'lib','t';
use TestTools;
use Test::Deep   qw/cmp_deeply/;

# use Log::Report mode => 3;  # debugging

use Data::Dumper;
$Data::Dumper::Indent = 1;

use XML::Compile::SOAP11::Client;
use XML::Compile::Tester;

use Test::More tests => 10;
use XML::LibXML;

my $schema = <<__HELPERS;
<schema targetNamespace="$TestNS"
  xmlns="$SchemaNS">

# mimic types of SOAP1.1 section 1.3 example 1
<element name="GetLastTradePrice">
  <complexType>
     <all>
       <element name="symbol" type="string"/>
     </all>
  </complexType>
</element>

<element name="GetLastTradePriceResponse">
  <complexType>
     <all>
        <element name="price" type="float"/>
     </all>
  </complexType>
</element>

<element name="Transaction" type="int"/>
</schema>
__HELPERS

#
# Create and interpret a message
#

my $soap = XML::Compile::SOAP11::Client->new;
isa_ok($soap, 'XML::Compile::SOAP11::Client');
isa_ok($soap, 'XML::Compile::SOAP11');

$soap->schemas->importDefinitions($schema);
#warn "$_\n" for sort $soap->schemas->elements;

my @msg1_struct = 
  ( header => [ transaction => "{$TestNS}Transaction" ]
  , body =>   [ request => "{$TestNS}GetLastTradePrice" ]
  );

my $msg1_data =
  { transaction => 5
  , request     => {symbol => 'DIS'}
  };

my $msg1_soap = <<__MESSAGE1;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope
   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Header>
    <x0:Transaction
      xmlns:x0="http://test-types"
      SOAP-ENV:mustUnderstand="1"
      SOAP-ENV:actor="http://schemas.xmlsoap.org/soap/actor/next http://actor">
        5
    </x0:Transaction>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <x0:GetLastTradePrice xmlns:x0="http://test-types">
      <symbol>DIS</symbol>
    </x0:GetLastTradePrice>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__MESSAGE1

# Sender
# produce message

my $client1 = $soap->compileMessage
 ( SENDER => @msg1_struct
 , mustUnderstand => 'transaction'
 , destination    => [ transaction => 'NEXT http://actor' ]
 );

is(ref $client1, 'CODE', 'compiled a client');

my $xml1 = $client1->($msg1_data);

isa_ok($xml1, 'XML::LibXML::Node', 'produced XML');
compare_xml($xml1, $msg1_soap);

#
# check the structure
# as a complication, the prefix is not really interpreted as prefix
# after the creation of the message...

my $xml1a = XML::LibXML->new->parse_string($xml1->toString(1));
my $struct = $soap->messageStructure($xml1a);
ok(defined $struct, 'got message structure');
cmp_deeply($struct, { body   => [ '{http://test-types}GetLastTradePrice' ],
                    , header => [ '{http://test-types}Transaction' ]
                    , wsa_action => undef
                    });


# Receiver
# Interpret incoming message

my $server1 = $soap->compileMessage(RECEIVER => @msg1_struct);

is(ref $server1, 'CODE', 'compiled a server');

my $hash1 = $server1->($msg1_soap);
is(ref $hash1, 'HASH', 'produced HASH');

cmp_deeply($hash1, $msg1_data, "server parsed input");
