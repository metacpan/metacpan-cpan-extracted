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

plan tests => 48 * @sorted;

sub test {
	my ($tree) = @_;

	my @pairs = @sorted;

	my $i = 0;
	my $cursor = $tree->new_cursor;
	while (my @pair = $cursor->next) {
		$cursor->delete;
		shift @pairs;
		is_deeply([ $tree->pairs ], \@pairs);
	}
}

runtests;
