use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/overload/reify.pm',
    't/00-compile.t',
    't/00-report-prereqs.t',
    't/lib/Parent.pm',
    't/method_names.t',
    't/modify.t',
    't/options.t',
    't/parent.t',
    't/redefine.t',
    't/wrap.t',
    't/wrap_loop.t'
);

notabs_ok($_) foreach @files;
done_testing;
