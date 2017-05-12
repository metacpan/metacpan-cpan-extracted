#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 26;

for my $module (glob("urpm/*.pm")) {
    $module =~ s,/,::,g;
    $module =~ s,\.pm$,,;
    use_ok $module;
}
