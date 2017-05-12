#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

eval 'use Test::Pod 1.00';

if ( $EVAL_ERROR ) {
    plan skip_all => 'Test::Pod 1.00 required for testing POD';
}

# Try lib, bin, cgi-bin one level up if run from t/
# perl Build test or make test run from top-level dir.
my @dirs = ();       # empty is fine - default include lib/
if (-d '../t/') {    # we are inside t/
    @dirs = (
        '../lib',
        '../doc',
    );
}

my @files = all_pod_files(@dirs);

plan tests => scalar(@files);

foreach my $module (@files) {
    pod_file_ok( $module );
}
