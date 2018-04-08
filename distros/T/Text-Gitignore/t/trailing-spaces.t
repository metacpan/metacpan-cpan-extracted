use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'ignore trailing spaces' => sub {
    my (@matched) = match_gitignore(['foo   '], 'foo');

    is_deeply \@matched, ['foo'];
};

subtest 'not ignore escaped trailing spaces' => sub {
    my (@matched) = match_gitignore(['foo\ '], 'foo');

    is_deeply \@matched, [];
};

done_testing;
