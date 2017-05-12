# vim: set ft=perl :

use strict;
use warnings;

use Test::More;
use Tree::BPTree;
require 't/runtests.pl';
use vars qw( &runtests @splitstr );

my $i = 0;
my @sorted = 
	sort { $a->[1] cmp $b->[1] }
	map { [ $i++, $_ ] } 
	@splitstr;

plan tests => 48;

sub test {
	my ($tree) = @_;

	my $i = 0;
	my @rtree  = $tree->map(sub { [ reverse(@_) ] });

	is_deeply(\@rtree, \@sorted);
}

runtests;
