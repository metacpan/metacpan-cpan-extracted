use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'ignore commented out lines' => sub {
    my (@matched) = match_gitignore(['#foo'], 'foo');

    is_deeply \@matched, [];
};

subtest 'not ignore escaped comments' => sub {
    my (@matched) = match_gitignore(['\#foo'], '#foo');

    is_deeply \@matched, ['#foo'];
};

done_testing;
