#!/usr/bin/env perl

# test string rewrite
use warnings;
use strict;

use XML::Compile::RPC::Client;
use XML::Compile::Tester;
use Test::More tests => 4;

my $rpc = XML::Compile::RPC::Client->new(destination => 'dummy');
my $hello = 'Hello, World!';
 
my ($rc, $data) = $rpc->_respmsg(<<__RESPONSE);
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><string>$hello</string></value>
    </param>
  </params>
</methodResponse>
__RESPONSE

cmp_ok($rc, '==', 0, 'correct messsage');
is($data, $hello, 'explicit string');
 
my ($rc2, $data2) = $rpc->_respmsg(<<__RESPONSE);
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value>$hello</value>
    </param>
  </params>
</methodResponse>
__RESPONSE

cmp_ok($rc2, '==', 0, 'correct messsage');
is($data2, $hello, 'implicit string');
