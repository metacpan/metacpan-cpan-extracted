use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WWW/Desk.pm',
    'lib/WWW/Desk/Auth/HTTP.pm',
    'lib/WWW/Desk/Auth/oAuth.pm',
    'lib/WWW/Desk/Auth/oAuth/SingleAccessToken.pm',
    'lib/WWW/Desk/Browser.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-unit-test.t',
    't/02-unit-test.t',
    't/03-unit-test.t',
    't/04-unit-test.t',
    't/boilerplate.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
