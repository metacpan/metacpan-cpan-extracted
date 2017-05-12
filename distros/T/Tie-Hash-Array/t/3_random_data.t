#!perl -Tw

use strict;

sub randomstring() {
    my $string = '';
    $string .= chr 32 + rand 96 while rand > 1 / 42;
    $string;
}

my %norm_hash;
BEGIN { %norm_hash = map randomstring(), 1 .. int 2410 * rand() << 1 }

use Test::More tests => 4 + 3 * keys %norm_hash;

BEGIN { use_ok 'Tie::Hash::Array' }					# test

tie my %tied_hash, 'Tie::Hash::Array';
isa_ok tied %tied_hash, 'Tie::Hash::Array';				# test

%tied_hash = %norm_hash;
my @sorted_keys = sort keys %norm_hash;

ok eq_hash( \%tied_hash, \%norm_hash ), 'hash content';			# test
is "@{[ keys %tied_hash ]}", "@sorted_keys", 'order of keys';		# test

for (@sorted_keys) {
    my( $key, $value ) = each %tied_hash;
    is $key, $_, 'keys while deleting';					# tests
    is $value, $norm_hash{$_}, 'values from each()';			# tests
    is delete $tied_hash{$_}, $norm_hash{$_}, 'values while deleting';	# tests
}
