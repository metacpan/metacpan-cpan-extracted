use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok 'WebService::PagerDuty';
    use_ok 'WebService::PagerDuty::Event';
    use_ok 'WebService::PagerDuty::Incidents';
    use_ok 'WebService::PagerDuty::Schedules';
    use_ok 'WebService::PagerDuty::Request';
    use_ok 'WebService::PagerDuty::Response';
}

