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

# --- IGNORE abcd

I1
I2
I3

# --- SKIP efgh

S1
S2
S3

ijkl

# ---

_END_

$t0 = Text::Clip->new( data => $data );

my $pattern = qr/^#[^\S\n]*---[^\S\n]*(\S+)?/m;

$t0 = $t0->find( $pattern );
is( $t0->match( 0 ), 'IGNORE' );
cmp_deeply( [ $t0->slurp( '@[)', chomp => 1 ) ], [ '', qw/ M1 M2 M3 /, '' ] );

$t0 = $t0->find( $pattern );
is( $t0->match( 0 ), 'SKIP' );
is( $t0->slurp( '()' ), <<_END_ );

I1
I2
I3

_END_

$t0 = $t0->find( $pattern );
is( $t0->match( 0 ), undef );
is( $t0->slurp(), <<_END_ );
# --- SKIP efgh

S1
S2
S3

ijkl

_END_

is( $t0->remaining, <<_END_ );

_END_

$data = <<_END_;

A1
A2


B1
B2
B3


C1
C2
_END_

chomp $data;
$t0 = Text::Clip->new( data => $data );
my @got;
while( $t0 = $t0->find( qr/(\n\n+|\Z)/ ) ) {
    push @got, map { s/^\s*//; s/\s*$//; $_ } $t0->slurp;
}
cmp_deeply( \@got, [ "A1\nA2", "B1\nB2\nB3", "C1\nC2" ] );
