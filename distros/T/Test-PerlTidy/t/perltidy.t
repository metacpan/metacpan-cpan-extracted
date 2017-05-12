#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::PerlTidy;

my $perltidyrc = File::Spec->catfile( 't', '_perltidyrc.txt' );

run_tests( perltidyrc => $perltidyrc );
