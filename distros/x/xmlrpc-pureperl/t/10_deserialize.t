#!/usr/bin/perl

use strict;
use lib qw(../lib);
use XMLRPC::PurePerl;
use Data::Dumper;
use Test;

BEGIN { plan tests => 8 }

print "Testing decode functions\n"; 
my $tests = {
  'string'  => { 'out' => 'foo', 'in' => '<value><string>foo</string></value>' },
  'array'   => { 'out' => [], 'in' => "<value><array><data></data></array></value>" },
  'hash'    => { 'out' => {}, 'in' => "<value><struct></struct></value>" },
  'date'    => { 'out' => XMLRPC::PurePerl->date("20060302"), 'in' => "<value><dateTime.iso8601>20060302T00:00:00</dateTime.iso8601></value>" },
  'double'  => { 'out' => 123.123, 'in' => "<value><double>123.123</double></value>" },
  'i4'      => { 'out' => 123, 'in' => "<value><i4>123</i4></value>" },
  'boolean' => { 'out' => XMLRPC::PurePerl->boolean(1), 'in' => "<value><boolean>1</boolean></value>" },
  'base64'  => { 'out' => XMLRPC::PurePerl->base64("ABC102="), 'in' => "<value><base64>ABC102=</base64></value>" }
};

foreach my $k ( sort(keys(%{$tests})) ) {
  my $res = XMLRPC::PurePerl->decode_variable( $tests->{$k}{'in'} );
  if ( ref($res) && ref($res) eq ref($tests->{$k}{'out'}) || $res eq $tests->{$k}{'out'} ) {
    ok(1);
  } else {
    ok(0);
  }
}

