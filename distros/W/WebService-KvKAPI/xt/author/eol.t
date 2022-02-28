use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/query-kvk.pl',
    'lib/WebService/KvKAPI.pm',
    'lib/WebService/KvKAPI/BasicProfile.pm',
    'lib/WebService/KvKAPI/Formatters.pm',
    'lib/WebService/KvKAPI/LocationProfile.pm',
    'lib/WebService/KvKAPI/Roles/OpenAPI.pm',
    'lib/WebService/KvKAPI/Search.pm',
    't/00-compile.t',
    't/001-openapi.t',
    't/100-search.t',
    't/200-basic-profile.t',
    't/300-location-profile.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
