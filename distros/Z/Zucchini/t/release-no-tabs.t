
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Zucchini.pm',
    'lib/Zucchini/Config.pm',
    'lib/Zucchini/Config/Create.pm',
    'lib/Zucchini/Contributors.pod',
    'lib/Zucchini/Fsync.pm',
    'lib/Zucchini/Manual/Tutorial.pod',
    'lib/Zucchini/Rsync.pm',
    'lib/Zucchini/Template.pm',
    'lib/Zucchini/Types.pm',
    'script/zucchini'
);

notabs_ok($_) foreach @files;
done_testing;
