#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Test::PerlTidy::XTFiles;

use constant CLASS => 'Test::PerlTidy::XTFiles';

chdir 'corpus/empty' or die "chdir failed:  $!";

my $obj = CLASS()->new;
isa_ok( $obj, CLASS(), 'new() returns a ' . CLASS() . ' object' );

is( $obj->perltidyrc, undef, 'perltidyrc is not defined' );
is( $obj->mute,       undef, 'mute is not defined' );

$obj = CLASS()->new( perltidyrc => 'nonexisting_file.txt', mute => 1 );
isa_ok( $obj, CLASS(), 'new(...) returns a ' . CLASS() . ' object' );

is( $obj->perltidyrc, 'nonexisting_file.txt', 'perltidyrc returnes the config file' );
is( $obj->mute, 1, 'mute returnes 1' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
