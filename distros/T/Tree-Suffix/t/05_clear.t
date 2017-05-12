use strict;
use warnings;
use Test::More tests => 1;
use Tree::Suffix;

my $tree = Tree::Suffix->new(qw(string stringy astring astringy));
$tree->clear;
is($tree->strings, 0, 'clear');
