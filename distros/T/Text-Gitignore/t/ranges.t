use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'match ranges' => sub {
    my (@matched) = match_gitignore( ['f[a-z]o'], 'foo', 'f1a' );

    is_deeply \@matched, ['foo'];
};

done_testing;
