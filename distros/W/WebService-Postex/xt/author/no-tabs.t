use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WebService/Postex.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/02-bug-baseuri-context.t',
    't/03-lwp-injection.t'
);

notabs_ok($_) foreach @files;
done_testing;
