#!/usr/bin/perl -w
use strict;
use Test::More tests => 9;
use Tie::Hash::Approx;

my (%hash, %res);
my $x = tie %hash, 'Tie::Hash::Approx';

ok( ref $x eq 'Tie::Hash::Approx', "tying hash to Tie::Hash::Approx" );

%hash = (
    key   => 'value',
    kay   => 'another value',
    stuff => 'yet another stuff',
);

ok( $hash{key}   eq 'value',             'exact match' );
ok( $hash{staff} eq 'yet another stuff', 'approx match' );

@res{ tied(%hash)->FETCH('koy') }++;

ok( exists( $res{'value'} ) && exists( $res{'another value'} ),
    'wantarray approx match' );

ok( exists( $hash{'key'} ),   'exists exact match' );
ok( exists( $hash{'staff'} ), 'exists approx match' );
ok( !exists( $hash{''} ), 'exists empty match' );

delete $hash{koy};
ok( !exists( $hash{'key'} ) && !exists( $hash{'kay'} ), 'deleting several approx matches' );

delete $hash{staff};
ok( !exists( $hash{'staff'} ), 'deleting approx match' );


