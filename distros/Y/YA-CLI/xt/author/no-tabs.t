use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/YA/CLI.pm',
    'lib/YA/CLI/ActionRole.pm',
    'lib/YA/CLI/ErrorHandler.pm',
    'lib/YA/CLI/Usage.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/100-base.t',
    't/lib/Test/YA/CLI/Example.pm',
    't/lib/Test/YA/CLI/Example/Main.pm',
    't/lib/Test/YA/CLI/Example/Something.pm'
);

notabs_ok($_) foreach @files;
done_testing;
