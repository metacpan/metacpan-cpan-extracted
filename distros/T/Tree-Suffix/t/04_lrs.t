use strict;
use warnings;
use Test::More tests => 2;
use Tree::Suffix;

my $tree = Tree::Suffix->new(qw(string stringy astring astringy));
my @lrs = $tree->lrs;
is_deeply([sort @lrs], [qw(astring stringy)], 'lrs');

@lrs = $tree->lrs(0, 5);
is_deeply(
    [sort @lrs],
    [qw(astri ringy strin strin tring tring)],
    'lrs(min, max)'
);
