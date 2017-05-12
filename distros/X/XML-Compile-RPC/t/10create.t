#!/usr/bin/env perl

# reproduce the examples from
# http://www.cafeconleche.org/books/xmljava/chapters/ch02s05.html

use warnings;
use strict;

use XML::Compile::RPC::Client;
use XML::Compile::Tester;
use Test::More tests => 7;

my $rpc = XML::Compile::RPC::Client->new(destination => 'dummy');
 
my $xml = $rpc->_callmsg('getQuote', string => 'RHAT');

compare_xml($xml, <<'__EXPECT');
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
  <methodName>getQuote</methodName>
  <params>
    <param>
      <value><string>RHAT</string></value>
    </param>
  </params>
</methodCall>
__EXPECT


my ($rc, $data) = $rpc->_respmsg(<<'__RESPONSE');
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><double>4.12</double></value>
    </param>
  </params>
</methodResponse>
__RESPONSE

cmp_ok($rc, '==', 0, 'correct messsage');
is_deeply($data, 4.12);

 
my @values = ({string => 'RHAT'}, {double => 4.12}, {double => 4.25});
my $xml2   = $rpc->_callmsg('getQuote', array => {data => {value => \@values}});

compare_xml($xml2, <<'__EXPECT');
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
  <methodName>getQuote</methodName>
  <params>
    <param>
      <value>
        <array>
          <data>
            <value><string>RHAT</string></value>
            <value><double>4.12</double></value>
            <value><double>4.25</double></value>
          </data>
        </array>
      </value>
    </param>
  </params>
</methodCall>
__EXPECT
 
my @members = ( {name => 'symbol', value => {string => 'RHAT'}}
              , {name => 'limit', value => {double => 2.25}}
              , {name => 'missing', value => {nil => {}}}
              , {name => 'expires', value =>
                   { 'dateTime.iso8601' => '2002-07-09T20:00:00Z' }} );

my $xml3   = $rpc->_callmsg('bid', struct => { member => \@members });

compare_xml($xml3, <<'__EXPECT');
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
  <methodName>bid</methodName>
    <params>
      <param>
        <value>
          <struct>
            <member>
              <name>symbol</name>
              <value><string>RHAT</string></value>
            </member>
            <member>
              <name>limit</name>
              <value><double>2.25</double></value>
            </member>
            <member>
              <name>missing</name>
              <value><nil/></value>
            </member>
            <member>
              <name>expires</name>
              <value><dateTime.iso8601>2002-07-09T20:00:00Z</dateTime.iso8601></value>
            </member>
          </struct>
        </value>
      </param>
    </params>
</methodCall>
__EXPECT

my ($rc2, $data2) = $rpc->_respmsg(<<'__RESPONSE');
<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>23</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>Unknown stock symbol ABCD</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
__RESPONSE

cmp_ok($rc2, '==', 23, 'fault messsage');
is_deeply($data2, 'Unknown stock symbol ABCD');
