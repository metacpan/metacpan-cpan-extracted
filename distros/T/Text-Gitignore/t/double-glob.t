use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'match deeply nested file' => sub {
    my (@matched) =
      match_gitignore( ['**/foo'], 'foo', 'hello/foo', 'deeply/nested/foo' );

    is_deeply \@matched, [ 'foo', 'hello/foo', 'deeply/nested/foo' ];
};

subtest 'match subdirs' => sub {
    my (@matched) =
      match_gitignore( ['foo/**'], 'foo', 'hello/foo', 'foo/deeply/nested' );

    is_deeply \@matched, ['foo/deeply/nested'];
};

subtest 'match deeply nested file extension' => sub {
    my (@matched) = match_gitignore( ['**.js'], 'foo.js', 'hello/foo.js',
        'deeply/nested/foo.js' );

    is_deeply \@matched, [ 'foo.js', 'hello/foo.js', 'deeply/nested/foo.js' ];
};

done_testing;
