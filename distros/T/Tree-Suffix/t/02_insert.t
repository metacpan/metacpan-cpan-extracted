use strict;
use warnings;
use Test::More tests => 8;
use Tree::Suffix;

{
    my $tree = Tree::Suffix->new();
    $tree->insert($_) for qw(string stringy astring);
    ok($tree->strings, 'strings');
    ok($tree->nodes, 'nodes');
    is($tree->strings, 3, 'insert($)');
    $tree->insert(undef);
    is($tree->strings, 3, 'undef');
    $tree->insert('');
    is($tree->strings, 3, 'empty string');
}

{
    my $tree = Tree::Suffix->new();
    $tree->insert(qw(string stringy astring));
    is($tree->nodes, 11, 'insert(@)');
    is_deeply([$tree->strings], [0, 1, 2], 'strings() in list context');
}

{
    my $tree = Tree::Suffix->new();
    $tree->insert(1..20);
    is($tree->strings, 20, 'ints');
}
