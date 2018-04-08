use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'ignore black lines' => sub {
    my (@matched) = match_gitignore([''], 'foo');

    is_deeply \@matched, [];
};

done_testing;
