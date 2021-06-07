use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Webservice/Judobase.pm',
    'lib/Webservice/Judobase.pod',
    'lib/Webservice/Judobase/Competitor.pm',
    'lib/Webservice/Judobase/Competitor.pod',
    'lib/Webservice/Judobase/Contests.pm',
    'lib/Webservice/Judobase/Contests.pod',
    'lib/Webservice/Judobase/General.pm',
    'lib/Webservice/Judobase/General.pod',
    't/00-Basic.t',
    't/00-compile.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
