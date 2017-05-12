# vim: set ft=perl :

use strict;
use warnings;

use Test::More;
use Tree::BPTree;
require 't/runtests.pl';
use vars qw( &runtests @splitstr );

plan tests => 2 * 48 * @splitstr;

my $i = 0;
my @pairs = reverse(map { [ $i++, $_ ] } @splitstr);

sub test {
	my ($tree) = @_;

	$tree->reverse;

	for my $pair (@pairs) {
		my $value = $tree->find($pair->[1]);
		my @values = $tree->find($pair->[1]);
		my @matched = grep { $_->[1] eq $pair->[1] } @pairs;

		is($value, $matched[0][0]);
		is_deeply(\@values, [ map { $_->[0] } @matched ]);
	}
}

runtests;
