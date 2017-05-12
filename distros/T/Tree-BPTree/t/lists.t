# vim: set ft=perl :

use strict;
use warnings;

use Test::More;
use Tree::BPTree;
require 't/runtests.pl';
use vars qw( &runtests @splitstr );

my $i = 0;
my @sorted_pairs = 
	sort { $a->[0] cmp $b->[0] }
	map { [ $_, $i++ ] } 
	@splitstr;
my @sorted_keys = map { $$_[0] } @sorted_pairs;
my @sorted_values = map { $$_[1] } @sorted_pairs;

plan tests => 3 * 48;

sub test {
	my ($tree) = @_;

	is_deeply([ $tree->pairs ], \@sorted_pairs);
	is_deeply([ $tree->keys ], \@sorted_keys);
	is_deeply([ $tree->values ], \@sorted_values);
}

runtests;
