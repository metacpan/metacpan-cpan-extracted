#!perl

use strict;
use warnings FATAL => 'all';

use Test::More 'no_plan';

use_ok('URI::mid');

my $MDF = 'mid%02d@foobar.local';
my $HDR = join ' ', map { sprintf "<$MDF>", $_ } (1..2);

#diag($HDR);

my @mids = URI::mid->parse($HDR);

is(scalar @mids, 2, 'Two objects in header');

map { isa_ok($_, 'URI::mid', $_) } @mids;

is($mids[0]->mid, sprintf($MDF, 1), 'First mid matches');

is($mids[0]->cid, undef, 'no cid yet');

$mids[0]->cid('1234@cid');

#diag($mids[0]);

my $cid = $mids[0]->cid;

isa_ok($cid, 'URI::cid', $cid);
#diag($cid);
