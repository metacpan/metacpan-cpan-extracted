use strict;
use warnings;
use Test::More tests => 13;
use Tree::Suffix;

my $tree = Tree::Suffix->new(qw(string bling string));
is($tree->strings, 3, 'string count');
is($tree->remove(qw(string)), 2, 'return count of remove');
is($tree->strings, 1, 'remaining strings');
is($tree->find('string'), 0, 'find removed string');
is($tree->allow_duplicates, 1, 'true flag value');

$tree->allow_duplicates(0);
ok(1, 'setting flag');
is($tree->insert(qw(bling)), 0, 'return count of insert');
is($tree->strings, 1, 'string count');
is($tree->allow_duplicates, 0, 'false flag value');

is($tree->allow_duplicates(undef), 0, 'undef');
is($tree->allow_duplicates("1"), 1, '"1"');
is($tree->allow_duplicates(""), 0, 'empty string');
is($tree->allow_duplicates("0"), 0, '"0"');
