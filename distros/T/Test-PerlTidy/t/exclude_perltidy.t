#!perl -T

use strict;
use warnings;

use File::Spec     ();
use Test::PerlTidy qw/ run_tests /;

my $perltidyrc = File::Spec->catfile( 't', '_perltidyrc.txt' );

run_tests(
    path       => '.',
    exclude    => [ 'blib', 'xt', qr#00-comp#, qr#Makefile#, qr#Build\.PL#, ],
    debug      => 0,
    perltidyrc => $perltidyrc
);
