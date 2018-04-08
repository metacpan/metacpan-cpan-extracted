use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'match file with glob' => sub {
    my (@matched) = match_gitignore(['/*.c'], 'foo.c');

    is_deeply \@matched, ['foo.c'];
};

subtest 'match whole file' => sub {
    my (@matched) = match_gitignore(['/bin'], 'bin', 'usr/bin');

    is_deeply \@matched, ['bin'];
};

subtest 'not match subdirectories' => sub {
    my (@matched) = match_gitignore(['/*.c'], 'foo/bar.c');

    is_deeply \@matched, [];
};

done_testing;
