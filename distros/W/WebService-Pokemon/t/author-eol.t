
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
    'lib/WebService/Pokemon/Role/APIResource.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/01_instantiation.t',
    't/02_request.t',
    't/03_resource.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/cache/restcountries/6/a/6a252342e6a799bb6194f3ff36d4039f.dat',
    't/cache/restcountries/8/9/896ee129bac2ab6536b5cd58e4a62e3a.dat',
    't/cache/restcountries/9/2/9293b0e669d3d0d7c10a809f24cbedc9.dat',
    't/cache/restcountries/c/1/c197e38ef15b72f671511507599858ad.dat',
    't/cache/restcountries/e/8/e89bb9edae6f9dab9400d43c69c88480.dat',
    't/cache/restcountries/f/e/fe18fbbd40889df68c28b861eea4787a.dat',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
