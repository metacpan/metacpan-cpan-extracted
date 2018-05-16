
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WebService/Pokemon.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/01_instantiation.t',
    't/02_api_version.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t',
    't/v2/03_pokemon.t',
    't/v2/04_berry.t',
    't/v2/05_berry_firmness.t',
    't/v2/06_berry_flavor.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
