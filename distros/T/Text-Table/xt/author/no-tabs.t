use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
