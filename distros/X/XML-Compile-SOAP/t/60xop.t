#!/usr/bin/env perl
# Test XOP

use warnings;
use strict;

use lib 'lib','t';
use TestTools;
use MIME::Base64;
use XML::LibXML;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use XML::Compile::SOAP11::Client;
use XML::Compile::SOAP::Util qw/SOAP11ENV :xop10/;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Tester;
use XML::Compile::XOP;

use Test::More tests => 25;

my $soap11_env = SOAP11ENV;
my $xmime      = XMIME11;
my $xop10      = XOP10;

my $test_bin   = "Hello, World!\n";
my $test_enc   = encode_base64 $test_bin;

my $schema = <<_SCHEMA;
<schema targetNamespace="$TestNS"
  xmlns="$SchemaNS">

  <element name="top">
    <complexType>
      <sequence>
        <element name="first"  type="base64Binary" />
        <element name="second" type="base64Binary" />
      </sequence>
    </complexType>
  </element>

</schema>
_SCHEMA

#
# Create and interpret a message
#

my $soap = XML::Compile::SOAP11::Client->new;
ok(defined $soap, 'create client');

$soap->schemas->importDefinitions($schema);

my @msg_struct = ( body => [ request => "{$TestNS}top" ] );

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
    <x0:top xmlns:x0="$TestNS">
      <first>$test_enc</first>
      <second>$test_enc</second>
    </x0:top>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__MSG1

my $msg1_data = {request => { first => $test_bin, second => $test_bin }};
my $xml1a = $sender->($msg1_data);
isa_ok($xml1a, 'XML::LibXML::Node', 'produced XML');
compare_xml($xml1a, $msg1_soap);

my $hash1 = $receiver->($msg1_soap);
is(ref $hash1, 'HASH', 'produced HASH');

is_deeply($hash1, $msg1_data, "server parsed input");

###
### Now with a XOP::Include
###

my $xop = XML::Compile::XOP->new;
isa_ok($xop, 'XML::Compile::XOP');

my $first_xop = $xop->bytes($test_bin, cid => 'mycid2@home');
isa_ok($first_xop, 'XML::Compile::XOP::Include');
is($first_xop, $test_bin, 'test stringification');
cmp_ok(length $first_xop, '==', length $test_bin, "fallback");

my $msg2_data = {request => { first => $first_xop, second => $test_bin }};
my ($xml2, $mtom2) = $sender->($msg2_data);
isa_ok($xml2, 'XML::LibXML::Node', 'produced XML');
compare_xml($xml2, <<_XML2);
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="$soap11_env">
  <SOAP-ENV:Body>
    <x0:top xmlns:x0="$TestNS">
      <first xmlns:xmime="$xmime" xmime:contentType="application/octet-stream">
         <xop:Include xmlns:xop="$xop10" href="cid:mycid2\@home"/>
      </first>
      <second>$test_enc</second>
    </x0:top>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
_XML2

cmp_ok(scalar @$mtom2, '==', 1, 'one xop object');
isa_ok($mtom2->[0], 'XML::Compile::XOP::Include');

my $http2 = $mtom2->[0]->mimePart;
isa_ok($http2, 'HTTP::Message');
is($http2->as_string("\n"), <<_HTTP2);
Content-Type: application/octet-stream
Content-ID: <mycid2\@home>
Content-Transfer-Encoding: binary

Hello, World!
_HTTP2

sub transport_bounce_request($$)
{   my ($request, $trace) = @_;

    my $response = HTTP::Response->new(200 => 'OK', $request->headers->clone);
    $response->parts( map {$_->clone} $request->parts );
    $response;
}

my $transporter = XML::Compile::Transport::SOAPHTTP->new;
ok(defined $transporter, 'soaphttp');

my $call2   = $transporter->compileClient(hook => \&transport_bounce_request);
isa_ok($call2, 'CODE', 'transport hook');

my $trace2  = {};
my ($xmltext2, $back2) = $call2->($xml2, $trace2, $mtom2);
isa_ok($xmltext2, 'XML::LibXML::Node');

isa_ok($mtom2, 'ARRAY', 'returned XOPs');
cmp_ok(scalar @$mtom2, '==', 1);
is($mtom2->[0]->cid, 'mycid2@home');

my $hash2 = $receiver->($xmltext2, $back2);

isa_ok($hash2, 'HASH', 'produced HASH');
 
#warn Dumper $hash2;
my $exp2 = { request =>
  { first => XML::Compile::XOP::Include->new(bytes => \"Hello, World!\n"
     , type => 'application/octet-stream', cid => 'mycid2@home'
     , charset => undef)
  , second => "Hello, World!\n"
  }};

is_deeply($hash2, $exp2 , "server parsed input");

