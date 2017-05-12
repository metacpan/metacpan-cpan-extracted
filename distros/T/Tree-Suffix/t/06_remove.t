use strict;
use warnings;
use Test::More tests => 5;
use Tree::Suffix;

my $tree = Tree::Suffix->new(qw(string stringy astring astringy));
is($tree->remove(qw(stringy astringy)), 2, 'return count');
is($tree->strings, 2, 'remaining nodes');
is_deeply([$tree->strings], [0, 2], 'strings() in list context');
$tree->remove(undef);
is($tree->strings, 2, 'undef');
$tree->remove('');
is($tree->strings, 2, 'empty string');
