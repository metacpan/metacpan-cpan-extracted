use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(match_gitignore);

subtest 'match extension glob' => sub {
    my (@matched) = match_gitignore( ['foo.*'], 'foo.bar' );

    is_deeply \@matched, ['foo.bar'];
};

subtest 'match filename glob' => sub {
    my (@matched) = match_gitignore( ['*.js'], 'foo.js' );

    is_deeply \@matched, ['foo.js'];
};

subtest 'not match glob' => sub {
    my (@matched) = match_gitignore( ['*.js'], 'foo.bar' );

    is_deeply \@matched, [];
};

subtest 'not match partly' => sub {
    my (@matched) = match_gitignore( ['*.js'], 'foo.json' );

    is_deeply \@matched, [];
};

subtest 'match double glob' => sub {
    my (@matched) = match_gitignore( ['*.js*'], 'foo.json' );

    is_deeply \@matched, ['foo.json'];
};

subtest 'not match glob with negation' => sub {
    my (@matched) = match_gitignore( ['!*.js'], 'foo.js' );

    is_deeply \@matched, [];
};

subtest 'match nested' => sub {
    my (@matched) =
      match_gitignore( ['*.html'], 'Documentation/git.html' );

    is_deeply \@matched, ['Documentation/git.html'];
};

subtest 'match filename with path' => sub {
    my (@matched) =
      match_gitignore( ['Documentation/*.html'], 'Documentation/git.html' );

    is_deeply \@matched, ['Documentation/git.html'];
};

subtest 'match direct subdirs' => sub {
    my (@matched) =
      match_gitignore( ['Documentation/*.html'],
        'tools/perf/Documentation/perf.html' );

    is_deeply \@matched, ['tools/perf/Documentation/perf.html'];
};

subtest 'not match not direct subdirs' => sub {
    my (@matched) =
      match_gitignore( ['Documentation/*.html'], 'Documentation/ppc/ppc.html' );

    is_deeply \@matched, [];
};

subtest 'match not direct subdirs' => sub {
    my (@matched) =
      match_gitignore( ['Documentation/*.html'], 'Documentation/ppc/ppc.html' );

    is_deeply \@matched, [];
};

done_testing;
