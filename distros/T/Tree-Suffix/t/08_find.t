use strict;
use warnings;
use Test::More tests => 14;
use Tree::Suffix;

my $tree = Tree::Suffix->new(qw(string stringy astring astringy));
is($tree->find('sting'), 0, 'non-existent substring');
is($tree->find('string'), 4, 'existing string');
is($tree->find('stri'), 4, 'existing prefix');
is($tree->find('ing'), 4, 'existing suffix');
is($tree->find(undef), 0, 'undef');
is($tree->find(''), 0, 'empty string');

$tree = Tree::Suffix->new(qw(mississippi));
is_deeply([$tree->find(undef)], [], 'undef in list context');
is_deeply([$tree->find('')], [], 'empty string in list context');
is_deeply([$tree->find('mis')], [[0, 0, 2]], 'list context');
is_deeply(
    [sort_arefs($tree->find('ss'))], [[0, 2, 3], [0, 5, 6]], 'list context'
);
$tree = Tree::Suffix->new(qw(actgttact gactagcga gacacacta));
is_deeply(
    [sort_arefs($tree->find('act'))],
    [[0, 0, 2], [0, 6, 8], [1, 1, 3], [2, 5, 7]], 'list context'
);
is_deeply([$tree->find('virus')], [], 'no match in list context');

TODO: {
    local $TODO = 'RT #43650 is still unsolved';

    $tree = Tree::Suffix->new('(IBAAR)(IBABR)(IBAR)');
    is($tree->find('IBR'), 0, 'RT #43650 - scalar');
    is_deeply([$tree->find('IBR')], [], 'RT #43650 - list');
}


sub sort_arefs {
    map  { $_->[0] }
    sort { $a->[1] cmp $b->[1] }
    map  { [$_, join(' ', @$_)] }
    @_;
}
