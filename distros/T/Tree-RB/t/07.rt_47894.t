use Test::More tests => 2;
use strict;
use warnings;
use Tree::RB;

my $tree = Tree::RB->new();
my $iter = $tree->iter();
my $iter_with_key = $tree->iter('somekey');

ok(!defined $iter->next, 'iterate empty tree');
ok(!defined $iter_with_key->next,  'iterate empty tree with key');
