#!/usr/bin/env perl

# test date rewrite
use warnings;
use strict;

use XML::Compile::RPC::Client;
use XML::Compile::Tester;
use Test::More tests => 3;

my $rpc = XML::Compile::RPC::Client->new(destination => 'dummy');
 
my $iso_date    = '20020709T202122Z';
my $schema_date = '2002-07-09T20:21:22Z';

### reading dates

my ($rc, $data) = $rpc->_respmsg(<<__RESPONSE);
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><dateTime.iso8601>$iso_date</dateTime.iso8601></value>
    </param>
  </params>
</methodResponse>
__RESPONSE

cmp_ok($rc, '==', 0, 'correct messsage');
is($data, $schema_date, 'rewrite read');
 
### writing dates

my $xml = $rpc->_callmsg('getQuote', 'dateTime.iso8601' => $iso_date);

compare_xml($xml, <<__EXPECT);
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
  <methodName>getQuote</methodName>
  <params>
    <param>
      <value><dateTime.iso8601>$schema_date</dateTime.iso8601></value>
    </param>
  </params>
</methodCall>
__EXPECT

