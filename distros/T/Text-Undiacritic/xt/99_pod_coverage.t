#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

eval 'use Test::Pod::Coverage 1.04';

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Pod::Coverage 1.00 required for testing POD';
    plan skip_all => skip_all => $msg;
}

my @dirs = ( 'lib' );
if (-d '../t/') {       # we are inside t/
    @dirs = ('../lib');
}
else {                  # we are outside t/
    # add ./lib to include path if blib/lib is not there (e.g. we're not
    # run from Build test or the like)
    push @INC, './lib' if not grep { $_ eq 'blib/lib' } @INC;
}

my @files = all_modules( @dirs );

#use Data::Dumper;
#die Dumper \@files;

plan tests => scalar @files;
foreach (@files) {
    pod_coverage_ok( $_ ,
    {
        private => [
           qr/^_/,
        ]
    });
}
