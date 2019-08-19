#!/usr/bin/perl
use strict; use warnings;
# vim=:SetNumberAndWidth

use Test::More;
#
#	Note, nxt line illustrates an Xporter-specific feature
#	'!' - negate all default exports, then add 'blessed'
use Types::Core qw(! blessed);
#

my $a={};

ok(! blessed $a, "not blessed test");

bless $a, "blessme";

ok(blessed $a, "blessed a test");

our $h = do { eval "HASH" };

ok(!defined $h, "no HASH test");

done_testing();
