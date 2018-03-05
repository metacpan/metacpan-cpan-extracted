#!/usr/bin/env perl
# Test charset conversion in http traffic

use warnings;
use strict;

use lib 'lib','t';
use TestTools;
use Test::Deep   qw/cmp_deeply/;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use XML::Compile::Util qw/pack_type/;
use XML::Compile::SOAP11::Client;
use XML::Compile::Tester;

use Test::More tests => 12;

use XML::LibXML;
use Log::Report;

use utf8;
my $test_string = "\x{03b1}\x{03b2}";   # utf8 string alpha beta

my $schema = <<__HELPERS;
<schema targetNamespace="$TestNS"
  elementFormDefault="qualified"
  xmlns="$SchemaNS">

  <element name="data" type="string"/>

</schema>
__HELPERS

#
# Create and interpret a message
#

my $client = XML::Compile::SOAP11::Client->new;
isa_ok($client, 'XML::Compile::SOAP11::Client');

$client->schemas->importDefinitions($schema);

# Sender

my $output = $client->compileMessage
 ( 'SENDER'
 , body => [ request => pack_type($TestNS, 'data') ]
 );
is(ref $output, 'CODE', 'got writer');

# Receiver

my $input = $client->compileMessage
 ( 'RECEIVER'
 ,  body => [ request => pack_type($TestNS, 'data') ]
 );
is(ref $input, 'CODE', 'got reader');

# Transporter

sub fake_server(@)
{   my ($request, $trace) = @_;

    # Check the request

    isa_ok($request, 'HTTP::Request');
    is(lc($request->header('Content-Type')), 'text/xml; charset=utf-8');

    my $decoded_content = $request->decoded_content;
    ok(utf8::is_utf8($decoded_content), 'decoded_content is utf8');

    my $expect = <<__XML;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope
   xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Body>
    <x0:data xmlns:x0="http://test-types">$test_string</x0:data>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
__XML

    ok(utf8::is_utf8($expect), 'expect is utf8');

    compare_xml($decoded_content, $expect, 'request content');

    # Produce answer

    HTTP::Response->new
      ( 200
      , 'standard response'
      , [ 'Content-Type' => 'text/xml; charset="utf-8"' ]
      , $request->content
      );
}

use XML::Compile::Transport::SOAPHTTP;
my $transport = XML::Compile::Transport::SOAPHTTP->new;
my $http = $transport->compileClient(hook => \&fake_server);

my $test = $client->compileClient
 ( # the general part
   name      => 'trade price'
 , encode    => $output
 , decode    => $input
 , transport => $http
 );

ok(utf8::is_utf8($test_string), 'test_string is utf8');
my $answer = $test->(request => $test_string);

ok(defined $answer, 'call succeeded');
my $result = $answer->{request};

ok(defined $result, 'got result');
ok(utf8::is_utf8($result), 'result is utf8');
