
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
    'lib/WebService/PagerDuty.pm',
    'lib/WebService/PagerDuty/Base.pm',
    'lib/WebService/PagerDuty/Event.pm',
    'lib/WebService/PagerDuty/Incidents.pm',
    'lib/WebService/PagerDuty/Request.pm',
    'lib/WebService/PagerDuty/Response.pm',
    'lib/WebService/PagerDuty/Schedules.pm'
);

notabs_ok($_) foreach @files;
done_testing;
