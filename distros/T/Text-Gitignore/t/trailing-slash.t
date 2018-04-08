use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'match directory' => sub {
    my (@matched) = match_gitignore(['foo/'], 'foo/');

    is_deeply \@matched, ['foo/'];
};

subtest 'match files in a directory' => sub {
    my (@matched) = match_gitignore(['foo/'], 'foo/bar');

    is_deeply \@matched, ['foo/bar'];
};

done_testing;
