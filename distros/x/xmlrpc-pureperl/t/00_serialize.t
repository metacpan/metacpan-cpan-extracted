#!/usr/bin/perl

use strict;
use lib qw(../lib);
use XMLRPC::PurePerl;
use Data::Dumper;
use Test;

BEGIN { plan tests => 24 }

foreach my $dt ( "20060302", "20040303", "2003-10-10T10:13:14.000Z", "2004-04-22T00:00", "SEP 17, 2003 09:45", "04/22/2004 00:00", "2004/04/22 00:00:01 AM", "04/22/2004", "302100ZSEP04", "6 June 2006", "30 July 2005", "30 July 2005 11:12:13 PM", "July 30 2005 11:12PM", "20001109171203", "{ts '2003-06-23 12:21:43'}", "19980717T14:08:55" ) {
  my $val = XMLRPC::PurePerl->date($dt)->value();
  if ( $val =~ /^[0-9]{8}T[0-9]{2}:[0-9]{2}:[0-9]{2}$/ ) {
    ok(1);
  } else {
    warn "$dt = $val";
    ok(0);
  }
}

my $tests = {
  'string'  => { 'in' => 'foo', 'out' => '<value><string>foo</string></value>' },
  'array'   => { 'in' => [], 'out' => "<value><array><data></data></array></value>" },
  'hash'    => { 'in' => {}, 'out' => "<value><struct></struct></value>" },
  'date'    => { 'in' => XMLRPC::PurePerl->date("20060302"), 'out' => "<value><dateTime.iso8601>20060302T00:00:00</dateTime.iso8601></value>" },
  'double'  => { 'in' => XMLRPC::PurePerl->double(123.123), 'out' => "<value><double>123.123</double></value>" },
  'i4'      => { 'in' => XMLRPC::PurePerl->i4(123), 'out' => "<value><i4>123</i4></value>" },
  'boolean' => { 'in' => XMLRPC::PurePerl->boolean(1), 'out' => "<value><boolean>1</boolean></value>" },
  'base64'  => { 'in' => XMLRPC::PurePerl->base64("ABC102="), 'out' => "<value><base64>ABC102=</base64></value>" }
};

foreach my $k ( sort(keys(%{$tests})) ) {
  my $res = XMLRPC::PurePerl->encode_variable( $tests->{$k}{'in'} );
  $res =~ s/[\r\n]//g;
  if ( $res eq $tests->{$k}{'out'} ) {
    ok(1);
  } else {
    ok(0);
  }
}

=item
my $xml = qq(<?xml version="1.0"?>
<methodCall>
<methodName>myMethod</methodName>
<params>
<param>
<value><struct>
<member><name>boo</name><value><array><data>
<value><string>a</string></value>
<value><string>b</string></value>
<value><string>c</string></value>
</data></array></value>
</member>
</struct></value>
</param>
</params>
</methodCall>
);

print "Testing full encode\n";
my $structure = { 'boo' => [ qw(a b c) ] };
my $gen = XMLRPC::PurePerl->encode_call_xmlrpc( 'myMethod' ,$structure );

if ( $gen eq $xml ) {
  ok(1);
} else {
  ok(0);
}
=cut
