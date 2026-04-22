#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Pod::Coverage;

my %cover_args = ( also_private => ['append_and_current'], );

my @modules = all_modules();
if (@modules) {
    for my $module (@modules) {
        pod_coverage_ok( $module, \%cover_args, "Pod coverage on $module" );
    }
}
else {
    ok( 0, "No modules found." );
}

done_testing();
