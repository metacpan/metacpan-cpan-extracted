#!/usr/bin/env perl -w
use strict;
use warnings;

use constant NEW_PERL => 5.008;
use constant MIN_TPV  => 1.26;
use constant MIN_PSV  => 3.05;

use Test::More;

my @errors;

eval {
    require Test::Pod;
    require Pod::Simple;

    my $tpv = Test::Pod->VERSION;
    my $psv = Pod::Simple->VERSION;

    if ( $tpv < MIN_TPV ) {
        push @errors, "Test::Pod >= 1.26 (you have $tpv) is needed for this test.";
    }

    if ( $psv < MIN_PSV ) {
        push @errors, "Pod::Simple >= 3.05 (you have $psv) is needed for this test.";
    }

    1;
} or do {
    push @errors, 'Test::Pod & Pod::Simple are required for testing POD';
};

if ( $] < NEW_PERL ) {
   # Legacy perl does not have Encode.pm. Thus, Pod::Simple
   # can not handle utf8 encoding and it will die, the tests
   # will fail.
   push @errors, q{"=encoding utf8" directives in Pods don't work with legacy perl.};
}

@errors ? plan( skip_all => "Errors detected: @errors" )
        : Test::Pod::all_pod_files_ok()
        ;
