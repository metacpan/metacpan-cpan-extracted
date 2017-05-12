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

	my $i = 0;
	$tree->iterate(sub { is_deeply(\@_, $sorted[$i++]) });
}

runtests;
