#!/usr/bin/env perl
# Test SOAP

use warnings;
use strict;

use lib 'lib','t';
use TestTools;
use Test::Deep   qw/cmp_deeply/;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use XML::Compile::SOAP11::Client;
use XML::Compile::SOAP::Util qw/SOAP11ENV/;
use XML::Compile::Tester;

use Test::More tests => 35;
use XML::LibXML;

my $soap11_env = SOAP11ENV;

my $schema = <<__HELPERS;
<schema targetNamespace="$TestNS"
  xmlns="$SchemaNS">

  <element name="good" type="int"/>

  <element name="fault_one">
    <complexType>
      <sequence>
        <element name="help" type="string" />
      </sequence>
    </complexType>
  </element>

  <element name="fault_two" nillable="true">
    <complexType>
<sequence/>
</complexType>
  </element>

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

my @msg_struct = 
  ( body   => [ request => "{$TestNS}good"  ]
  , faults => [ fault1 => "{$TestNS}fault_one" ]
  );

my $sender   = $soap->compileMessage(SENDER => @msg_struct);
is(ref $sender, 'CODE', 'compiled a sender');

my $receiver = $soap->compileMessage(RECEIVER => @msg_struct);
is(ref $receiver, 'CODE', 'compiled a receiver');

#
# Message 1 is ok
#

# sender

my $msg1_soap = <<__MSG1;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="$soap11_env">
  <SOAP-ENV:Body>
    <x0:good xmlns:x0="$TestNS">3</x0:good>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__MSG1

my $xml1a = $sender->(request => 3);
isa_ok($xml1a, 'XML::LibXML::Node', 'produced XML');
compare_xml($xml1a, $msg1_soap);

my $xml1b = $sender->( {request => 3} );
isa_ok($xml1b, 'XML::LibXML::Node', 'produced XML');
compare_xml($xml1b, $msg1_soap);

# receiver

my $hash1 = $receiver->($msg1_soap);
is(ref $hash1, 'HASH', 'produced HASH');

cmp_deeply($hash1, {request => 3}, "server parsed input");

#
# Message 2 is fault1
#

my $msg2_soap = <<__MSG2;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="$soap11_env">
  <SOAP-ENV:Body>
    <SOAP-ENV:Fault
         xmlns:xsd="http://www.w3.org/2001/XMLSchema"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <faultcode>SOAP-ENV:Server.first</faultcode>
      <faultstring>my mistake</faultstring>
      <faultactor>http://schemas.xmlsoap.org/soap/actor/next</faultactor>
      <detail>
         <x0:fault_one xmlns:x0="$TestNS">
           <help>please ignore</help>
         </x0:fault_one>
      </detail>
    </SOAP-ENV:Fault>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__MSG2

my %fault1
 = ( fault1 =>
      { faultcode   => "{$soap11_env}Server.first"
      , faultstring => 'my mistake'
      , faultactor  => 'NEXT'
      , detail      => { help => 'please ignore' }
      }
   );

my $xml2 = $sender->(%fault1);
ok(defined $xml2, 'send message 2: fault1');
compare_xml($xml2, $msg2_soap, 'compare sent');

my $hash2 = $receiver->($msg2_soap);
is(ref $hash2, 'HASH', 'produced HASH');

### test Fault

ok(exists $hash2->{Fault}, 'encoded fault present');
my $fault = $hash2->{Fault};
ok(defined $fault);
like($fault->{faultcode}, qr/^\{.*\}Server.first$/, 'faultcode');
like($fault->{faultactor}, qr/^http:/, 'faultactor');
is($fault->{faultstring}, 'my mistake', 'faultstring');

ok(defined $fault->{detail}, 'detail');
is(ref $fault->{detail}, 'HASH');

my @keys = keys %{$fault->{detail}};
cmp_ok(scalar @keys, '==', 1);
my $key = $keys[0];
is($key, "{$TestNS}fault_one");
my $one = $fault->{detail}{$key};
ok(defined $one, 'has one');
is(ref $one, 'HASH');
cmp_ok(keys(%$one), '==', 1);
is($one->{help}, 'please ignore');

### test fault1
#use Data::Dumper;
#warn Dumper $hash2;

ok(exists $hash2->{fault1}, 'decoded fault present');
my $fault1 = $hash2->{fault1};
ok(defined $fault1);

is($fault1->{reason}, 'my mistake', 'reason');
like($fault1->{code}, qr/^\{.*\}Server.first$/, 'code');
is($fault1->{role}, 'NEXT', 'role');

my $class = $fault1->{class};
ok(defined $class, "class");
is($class->[1], 'Receiver');
is($class->[2], 'first');

ok(defined $fault1->{help});
