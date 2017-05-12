#!perl -T

use strict;
use Test::More tests => 1;

use XML::RPC 0.8;
my $xmlrpc = XML::RPC->new('http://example.ex');
isa_ok($xmlrpc,'XML::RPC');
