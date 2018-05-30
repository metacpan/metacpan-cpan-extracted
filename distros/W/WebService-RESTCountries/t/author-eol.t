
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
    'lib/WebService/RESTCountries.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/00_compile.t',
    't/01_instantiation.t',
    't/02_request.t',
    't/03_search_all.t',
    't/04_search_by_country_name.t',
    't/05_search_by_country_full_name.t',
    't/06_search_by_country_code.t',
    't/07_search_by_country_codes.t',
    't/08_search_by_currency.t',
    't/09_search_by_language_code.t',
    't/10_search_by_capital_city.t',
    't/11_search_by_calling_code.t',
    't/12_search_by_region.t',
    't/13_search_by_region_bloc.t',
    't/14_ping.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
