#!perl

use strict;
use warnings FATAL => 'all';

use Test::More 'no_plan';

use_ok('URI::cid');

my $CID  = '1234@foobar.local';
my $HDR  = sprintf '<%s>', $CID;

my $cid = URI::cid->parse($HDR);

isa_ok($cid, 'URI::cid', 'Parsed header');

is($cid->format, $HDR, 'Formats to header');


