# vim: set ft=perl :

use strict;
use warnings;

use Test::More;
use Tree::BPTree;
require 't/runtests.pl';
use vars qw( &runtests @splitstr );

my $i = 0;
my @sorted = 
	sort { $a->[0] cmp $b->[0] }
	map { [ $_, $i++ ] }
	@splitstr;

plan tests => 3 * 48 * @sorted;

sub test {
	my ($tree) = @_;

	my $i = 0;
	my $c1 = $tree->new_cursor;
	my $c2 = $tree->new_cursor;
	while (my @pair = $c1->each) {
		is_deeply([ $c1->current ], \@pair);
		is_deeply(\@pair, $sorted[$i++]);

		$c2->each; 
		my @pair = $c2->each;
		is_deeply(\@pair, $sorted[1]);
		$c2->reset;
	}
}

runtests;
