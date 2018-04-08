use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'match classes' => sub {
    my (@matched) = match_gitignore( ['f[oa]o'], 'foo', 'fao', 'fza');

    is_deeply \@matched, ['foo', 'fao'];
};

subtest 'match classes with negation' => sub {
    my (@matched) = match_gitignore( ['f[!oa]o'], 'fao', 'fzo');

    is_deeply \@matched, ['fzo'];
};

done_testing;
