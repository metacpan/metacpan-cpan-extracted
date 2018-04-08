use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'include negated files' => sub {
    my (@matched) = match_gitignore( [ 'f*', '!foo' ], 'f123', 'foo' );

    is_deeply \@matched, ['f123'];
};

subtest 'treat escaped negation as pattern' => sub {
    my (@matched) = match_gitignore( ['\!foo'], '!foo' );

    is_deeply \@matched, ['!foo'];
};

subtest 'negate dirs' => sub {
    my (@matched) = match_gitignore( [ '*.pm', '!tests/' ],
        'foo/tests/some/file.pm', 'lib.pm' );

    is_deeply \@matched, ['lib.pm'];
};

subtest 'negate glob path' => sub {
    my (@matched) = match_gitignore( [ '*.js', '!*.c' ], 'else.js', 'file.c' );

    is_deeply \@matched, ['else.js'];
};

subtest 'negate any path' => sub {
    my (@matched) = match_gitignore( [ '**.js', '!**.c' ],
        'somewhere/there/else.js', 'file.c' );

    is_deeply \@matched, ['somewhere/there/else.js'];
};

done_testing;
