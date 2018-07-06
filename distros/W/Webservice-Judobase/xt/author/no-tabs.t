use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Webservice/Judobase.pm',
    'lib/Webservice/Judobase.pod',
    'lib/Webservice/Judobase/Competitor.pm',
    'lib/Webservice/Judobase/Contests.pm',
    'lib/Webservice/Judobase/General.pm',
    't/00-Basic.t',
    't/00-compile.t',
    't/01-SubModules.t'
);

notabs_ok($_) foreach @files;
done_testing;
