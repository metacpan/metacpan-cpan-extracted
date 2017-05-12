#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Text::Clip;

my ( $t0, $content, $data );

$data = <<_END_;

M1
M2
M3

_END_

$t0 = Text::Clip->new( data => $data );

my $pattern = qr/\Z/m;
$t0 = $t0->find( $pattern );
cmp_deeply( [ $t0->slurp( '@[)', chomp => 1 ) ], [ '', qw/ M1 M2 M3 /, '' ] );
cmp_deeply( [ $t0->slurp( '@[)', chomp => 1, trim => 1 ) ], [ qw/ M1 M2 M3 / ] );
cmp_deeply( [ $t0->slurp( '@[)', chomp => 1, trimmed => 1 ) ], [ qw/ M1 M2 M3 / ] );
is( $t0->slurp( '$[]', chomp => 1, trimmed => 1 ) , "M1\nM2\nM3" );
