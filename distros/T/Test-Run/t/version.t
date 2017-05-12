#!/usr/bin/perl -Tw

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;

use Test::More tests => 3;

BEGIN {
    # TEST
    use_ok('Test::Run::Core');
}

my $ver = $ENV{HARNESS_NG_VERSION} or die "HARNESS_VERSION not set";
# TEST
like( $ver, qr/^\d.\d\d\d\d(_\d\d)?$/, "Version is proper format" );
# TEST
is( $ver, $Test::Run::Core::VERSION );

