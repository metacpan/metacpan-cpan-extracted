
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
    'lib/WebService/Pokemon/APIResourceList.pm',
    'lib/WebService/Pokemon/NamedAPIResource.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/00_load.t',
    't/02_request.t',
    't/03_resource.t',
    't/04_resource_by_url.t',
    't/05_api_resource_list.pm',
    't/06_named_api_resource.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-distmeta.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
