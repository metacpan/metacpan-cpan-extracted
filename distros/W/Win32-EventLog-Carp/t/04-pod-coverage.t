#!/usr/bin/perl

use strict;
use Test::More tests => 1;

my $have_Test_Pod_Coverage = do {
    eval "use Test::Pod::Coverage";
    $@ ? 0 : 1;
};

SKIP: {
    skip( 'Test::Pod::Coverage not installed on this system', 1 )
        unless $have_Test_Pod_Coverage;
    pod_coverage_ok( "Win32::EventLog::Carp", "POD coverage is go!" );
}
