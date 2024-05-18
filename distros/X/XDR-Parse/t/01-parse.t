#!perl

use strict;
use warnings;

use Test2::V0;

my $output = `$^X bin/xdr-parse < t/data/01-parse.x`;
is( $?, 0 );

done_testing;
