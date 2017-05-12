use strict;
use warnings;
use Test::More tests => 3;
use Tree::Suffix;

{
    my $tree = Tree::Suffix->new;
    isa_ok($tree, 'Tree::Suffix', 'new()');
}

{
    my $tree = Tree::Suffix->new(qw,testing one two three,);
    isa_ok($tree, 'Tree::Suffix', 'new(@list)');
}

{
    my @methods = qw(
        allow_duplicates insert strings nodes clear remove dump
        lcs longest_common_substrings lrs longest_repeated_substrings
        find match search string
    );
    can_ok('Tree::Suffix', @methods);
}
