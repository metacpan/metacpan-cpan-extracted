use strict;
use warnings;
use Test::More tests => 1;
use Tree::Suffix;

my $tree = Tree::Suffix->new;
$tree->insert('abc');
$tree->find('def');
$tree->insert('ghi');
is_deeply([$tree->find('ghi')], [[1, 0, 2]], 'index vs id');
