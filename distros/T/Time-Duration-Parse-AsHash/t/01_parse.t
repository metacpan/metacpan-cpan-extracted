#!perl

use strict;
use Test::More 0.98;

use Time::Duration::Parse::AsHash;

sub ok_duration {
    my($spec, $res) = @_;
    is_deeply(parse_duration($spec), $res) or diag explain $res;
}

sub ok_duration_as_num {
    my($spec, $res) = @_;
    is(parse_duration($spec, 1), $res) or diag explain $res;
}

sub fail_duration {
    my $spec = shift;
    eval { parse_duration($spec) };
    ok $@, $@;
}

ok_duration '3', {seconds=>3};
ok_duration '3 ns', {seconds=>3e-9};
ok_duration '3 microsecond', {seconds=>3e-6};
ok_duration '3 ms', {seconds=>3e-3};
ok_duration '3 seconds', {seconds=>3};
ok_duration '3 Seconds', {seconds=>3};
ok_duration '3 s', {seconds=>3};
ok_duration '6 minutes', {minutes=>6};
ok_duration '6 minutes and 3 seconds', {minutes=>6, seconds=>3};
ok_duration '6 Minutes and 3 seconds', {minutes=>6, seconds=>3};
ok_duration '1 day', {days=>1};
ok_duration '1 day, and 3 seconds', {days=>1, seconds=>3};
ok_duration '2 weeks', {weeks=>2};
ok_duration '2 months', {months=>2};
ok_duration '2 years', {years=>2};
ok_duration '2 decades', {years=>20};

# negative
ok_duration '-1 seconds', {seconds=>-1};
ok_duration '-6 minutes', {minutes=>-6};

ok_duration '1 hr', {hours=>1};
ok_duration '3s', {seconds=>3};
ok_duration '1hr', {hours=>1};
ok_duration '+2h', {hours=>2};

# h:m & h:m:s
ok_duration '1d 2:03', {days=>1, hours=>2, minutes=>3};
ok_duration '1d 2:03:01', {days=>1, hours=>2, minutes=>3, seconds=>1};
ok_duration '1d -24:00', {days=>1, hours=>-24};
ok_duration '2:03', {hours=>2, minutes=>3};
ok_duration '2:03:04', {hours=>2, minutes=>3, seconds=>4};
ok_duration '2:03:04.5', {hours=>2, minutes=>3, seconds=>4.5};

ok_duration ' 1s   ', {seconds=>1};
ok_duration '   1  ', {seconds=>1};
ok_duration '  1.3 ', {seconds=>1.3};

ok_duration '1.5h', {hours=>1.5};
ok_duration '1,5h', {hours=>1.5};
ok_duration '1.5h 30m', {hours=>1.5, minutes=>30};
ok_duration '1.9s', {seconds=>1.9};          # Check rounding
ok_duration '1.3s', {seconds=>1.3};
ok_duration '1.3', {seconds=>1.3};
ok_duration '1.9', {seconds=>1.9};

ok_duration '1h,30m, 3s', {hours=>1, minutes=>30, seconds=>3};
ok_duration '1h and 30m,3s', {hours=>1, minutes=>30, seconds=>3};
ok_duration '1,5h, 3s', {hours=>1.5, seconds=>3};
ok_duration '1,5h and 3s', {hours=>1.5, seconds=>3};
ok_duration '1.5h, 3s', {hours=>1.5, seconds=>3};
ok_duration '1.5h and 3s', {hours=>1.5, seconds=>3};

fail_duration '3 sss';
fail_duration '6 minutes and 3 sss';
fail_duration '6 minutes, and 3 seconds a';

# return number
ok_duration_as_num '6 minutes and 3 seconds', 363;

done_testing;
