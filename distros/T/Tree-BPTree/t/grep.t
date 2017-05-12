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

my @letters = ('A' .. 'Z', 'a' .. 'z');
my @matches = map { qr/^$letters[$_]/ } map { int(rand(scalar(@letters))) } 0 .. 9;

plan tests => 3 * 10 * 48;

sub test {
	my ($tree) = @_;

	for my $i (0 .. $#matches) {
		my $treematch = sub { $_[0] =~$matches[$i] };
		my $listmatch = sub { $$_[0] =~ $matches[$i] };
		is_deeply([ $tree->grep($treematch) ],
				  [ grep {&$listmatch($_)} @sorted ]);

		is_deeply([ $tree->grep_keys($treematch) ],
				  [ map { $_->[0] } grep {&$listmatch($_)} @sorted ]);

		is_deeply([ $tree->grep_values($treematch) ],
				  [ map { $_->[1] } grep {&$listmatch($_)} @sorted ]);
	}
}

runtests;
