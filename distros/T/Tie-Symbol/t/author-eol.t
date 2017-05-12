
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Tie/Symbol.pm',        't/00-check-deps.t',
    't/00-compile.t',           't/100-tie.t',
    't/101-fetch.t',            't/102-namespace.t',
    't/103-examine.t',          't/104-store.t',
    't/105-erase.t',            't/106-clear.t',
    't/200-new.t',              't/203-examine.t',
    't/author-critic.t',        't/author-eol.t',
    't/author-no-tabs.t',       't/release-cpan-changes.t',
    't/release-fixme.t',        't/release-kwalitee.t',
    't/release-pod-coverage.t', 't/release-pod-syntax.t'
);

eol_unix_ok( $_, { trailing_whitespace => 1 } ) foreach @files;
done_testing;
