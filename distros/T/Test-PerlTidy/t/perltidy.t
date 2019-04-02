#!perl -T

use strict;
use warnings;

use File::Spec ();
use Test::PerlTidy qw( run_tests );

my $perltidyrc = File::Spec->catfile( 't', '_perltidyrc.txt' );

run_tests(
    exclude    => [ qr/xt/, qr/00-comp/, qr/Build\.PL/, qr/Makefile\.PL/, ],
    perltidyrc => $perltidyrc
);
