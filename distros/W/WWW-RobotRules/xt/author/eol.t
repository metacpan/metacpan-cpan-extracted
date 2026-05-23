use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WWW/RobotRules.pm',
    'lib/WWW/RobotRules/AnyDBM_File.pm',
    'lib/WWW/RobotRules/DB_File.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/misc/dbmrobot',
    't/rules-dbm.t',
    't/rules.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
