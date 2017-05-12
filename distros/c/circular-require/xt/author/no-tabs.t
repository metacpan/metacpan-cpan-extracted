use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/circular/require.pm',
    't/00-compile.t',
    't/base.t',
    't/base2.t',
    't/base2/Bar.pm',
    't/base2/Foo.pm',
    't/basic.t',
    't/basic/Bar.pm',
    't/basic/Baz.pm',
    't/basic/Foo.pm',
    't/dynamic.t',
    't/dynamic2.t',
    't/dynamic2/Bar.pm',
    't/dynamic2/Baz.pm',
    't/dynamic2/Foo.pm',
    't/dynamic2/Quux.pm',
    't/dynamic3.t',
    't/dynamic3/Bar.pm',
    't/dynamic3/Bar2.pm',
    't/dynamic3/Bar3.pm',
    't/dynamic3/Baz.pm',
    't/dynamic3/Baz2.pm',
    't/dynamic3/Baz3.pm',
    't/dynamic3/Foo.pm',
    't/eval.t',
    't/eval/Bar.pm',
    't/eval/Foo.pm',
    't/hidden_cycle.t',
    't/hidden_cycle/Bar.pm',
    't/hidden_cycle/Baz.pm',
    't/hidden_cycle/Foo.pm',
    't/hide_middleman.t',
    't/hide_middleman/Bar.pm',
    't/hide_middleman/Foo.pm',
    't/hide_middleman2.t',
    't/hide_middleman3.t',
    't/injection.t',
    't/injection/Foo.pm',
    't/long_cycle.t',
    't/long_cycle/Bar.pm',
    't/long_cycle/Baz.pm',
    't/long_cycle/Blorg.pm',
    't/long_cycle/Foo.pm',
    't/long_cycle/Quux.pm',
    't/version.t'
);

notabs_ok($_) foreach @files;
done_testing;
