use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Text/Table.pm',
    't/00-compile.t',
    't/01_ini.t',
    't/10_Table.t',
    't/11_Variable_Rule.t',
    't/12_column_seps_as_hashes.t',
    't/13_callback_rules_with_whitespace.t',
    't/14_overload.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
