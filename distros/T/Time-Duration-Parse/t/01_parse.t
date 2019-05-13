use strict;
use Test::More 0.88;

use Time::Duration::Parse;

my @GOOD_TIME_SPECS = (
    ['3', 3],
    ['3 seconds', 3],
    ['3 Seconds', 3],
    ['3 s', 3],
    ['6 minutes', 360],
    ['6 minutes and 3 seconds', 363],
    ['6 Minutes and 3 seconds', 363],
    ['1 day', 86400],
    ['1 day, and 3 seconds', 86403],
    ['-1 seconds', -1],
    ['-6 minutes', -360],

    ['1 hr', 3600],
    ['3s', 3],
    ['1hr', 3600],
    ['+2h', 7200],
    ['1hrs', 3600],
    ['+2hrs', 7200],

    ['1d 2:03', 93780],
    ['1d 2:03:01', 93781],
    ['1d -24:00', 0],
    ['2:03', 7380],
    ['2:03:00', 7380],
    ['2:03:00.1', 7380],
    ['2:03:00.8', 7381],

    [' 1s   ', 1],
    ['   1  ', 1],
    ['  1.3 ', 1],

    ['1.5h', 5400],
    ['1,5h', 5400],
    ['1.5h 30m', 7200],
    ['1.9s', 2],          # Check rounding
    ['1.3s', 1],
    ['1.3', 1],
    ['1.9', 2],

    ['1h,30m, 3s', 5403],
    ['1h and 30m,3s', 5403],
    ['1,5h, 3s', 5403],
    ['1,5h and 3s', 5403],
    ['1.5h, 3s', 5403],
    ['1.5h and 3s', 5403],

    ['450 hrs', 1620000],
    ['170 hrs 35 mins 21 seconds', 614121],

    ['1 month', 2592000],
    ['2 months', 5184000],
    ['2 mo', 5184000],
    ['2 mon', 5184000],
    ['2 mons', 5184000],
);


my @BAD_TIME_SPECS = (
    '3 sss',
    '6 minutes and 3 sss',
    '6 minutes, and 3 seconds a',
);

plan tests => int(@GOOD_TIME_SPECS) + int(@BAD_TIME_SPECS);

foreach my $test (@GOOD_TIME_SPECS) {
    my ($spec, $expected_seconds) = @$test;
    ok_duration($spec, $expected_seconds);
}

foreach my $spec (@BAD_TIME_SPECS) {
    fail_duration($spec);
}

sub ok_duration {
    my($spec, $seconds) = @_;
    is parse_duration($spec), $seconds, "$spec = $seconds";
}

sub fail_duration {
    my $spec = shift;
    eval { parse_duration($spec) };
    ok $@, $@;
}
