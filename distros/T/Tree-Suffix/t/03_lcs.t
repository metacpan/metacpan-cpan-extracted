use strict;
use warnings;
use Test::More tests => 2;
use Tree::Suffix;

my $tree = Tree::Suffix->new(qw(string stringy astring));
my @lcs = $tree->lcs;
is_deeply(\@lcs, ['string'], 'lcs');

@lcs = $tree->lcs(0, 3);
is_deeply([sort @lcs], [qw(ing rin str tri)], 'lcs(min, max)');
