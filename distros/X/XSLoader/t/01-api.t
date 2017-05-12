#!perl -wT
use strict;
use Test::More tests => 2;

my $module = "XSLoader";
use_ok($module);
can_ok($module, qw< load bootstrap_inherit >);
