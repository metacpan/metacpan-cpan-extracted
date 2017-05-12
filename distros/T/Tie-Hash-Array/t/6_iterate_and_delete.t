#!perl -Tw

use strict;
use Test::More tests => 4;

BEGIN { use_ok 'Tie::Hash::Array' }					# test

tie my %tied_hash, 'Tie::Hash::Array';
isa_ok tied %tied_hash, 'Tie::Hash::Array';				# test

sub randomstring() {
    my $string = '';
    $string .= chr 32 + rand 96 while rand > 1 / 42;
    $string;
}

my @testdata;
push @testdata, randomstring for 1 .. 42;
%tied_hash = @testdata;
my %norm_hash = @testdata;

ok eq_hash( \%tied_hash, \%norm_hash ), 'hash content';			# test
is "@{[ keys %tied_hash ]}", "@{[ sort keys %norm_hash ]}", 'order of keys'
									# Test
