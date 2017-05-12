#!env perl

use strict;
use warnings;

use Test::More;
use Time::Local::TZ qw/tz_localtime tz_timelocal/;

my @TESTS = (
    [          0, "UTC",           "Thu Jan  1 00:00:00 1970", [  0,  0,  0,  1,  0,  70, 4,   0, 0 ] ],
    [          0, "Europe/Moscow", "Thu Jan  1 03:00:00 1970", [  0,  0,  3,  1,  0,  70, 4,   0, 0 ] ],
    [         -1, "UTC",           "Wed Dec 31 23:59:59 1969", [ 59, 59, 23, 31, 11,  69, 3, 364, 0 ] ],
    [      -3661, "Europe/Moscow", "Thu Jan  1 01:58:59 1970", [ 59, 58,  1,  1,  0,  70, 4,   0, 0 ] ],
    [ 1493043119, "Europe/Moscow", "Mon Apr 24 17:11:59 2017", [ 59, 11, 17, 24,  3, 117, 1, 113, 0 ] ],
);

plan tests => @TESTS*12 + 11;

ok(!eval { tz_localtime();              1}, "tz_localtime()");
ok(!eval { tz_localtime("UTC");         1}, "tz_localtime('UTC')");
ok(!eval { tz_localtime("UTC", 0, 123); 1}, "tz_localtime('UTC', 0, 123)");

ok(!eval { tz_timelocal();                                     1}, "tz_timelocal()");
ok(!eval { tz_timelocal("UTC");                                1}, "tz_timelocal('UTC')");
ok(!eval { tz_timelocal("UTC", 1);                             1}, "tz_timelocal('UTC', 1)");
ok(!eval { tz_timelocal("UTC", 1, 1);                          1}, "tz_timelocal('UTC', 1, 1)");
ok(!eval { tz_timelocal("UTC", 1, 1, 1);                       1}, "tz_timelocal('UTC', 1, 1, 1)");
ok(!eval { tz_timelocal("UTC", 1, 1, 1, 1);                    1}, "tz_timelocal('UTC', 1, 1, 1, 1)");
ok(!eval { tz_timelocal("UTC", 1, 1, 1, 1, 1);                 1}, "tz_timelocal('UTC', 1, 1, 1, 1, 1)");
ok(!eval { tz_timelocal("UTC", 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ); 1}, "tz_timelocal('UTC', 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 )");




foreach my $t (@TESTS) {
    my ($time, $tz, $asctime, $tm) = @$t;
    {
        local $ENV{TZ} = "Europe/Berlin";

        is(scalar tz_localtime($tz, $time), $asctime, "tz_localtime('$tz', $time') as string with TZ set");
        is($ENV{TZ}, "Europe/Berlin", "ENV{TZ} unchanged after tz_localtime call");

        is_deeply([ tz_localtime($tz, $time) ], $tm, "tz_localtime('$tz', $time) as array with TZ set");
        is($ENV{TZ}, "Europe/Berlin", "ENV{TZ} unchanged after tz_localtime call");
    }
    {
        delete local $ENV{TZ};
 
        is(scalar tz_localtime($tz, $time), $asctime, "tz_localtime('$tz', $time') as string with TZ unset");
        ok(!exists $ENV{TZ}, "ENV{TZ} unchanged after tz_localtime call");

        is_deeply([ tz_localtime($tz, $time) ], $tm, "tz_localtime('$tz', $time) as array with TZ unset");
        ok(!exists $ENV{TZ}, "ENV{TZ} unchanged after tz_localtime call");
    }
}

foreach my $t (@TESTS) {
    my ($time, $tz, $asctime, $tm) = @$t;
    {
        local $ENV{TZ} = "Europe/Berlin";
        is(tz_timelocal($tz, @$tm), $time, "tz_timelocal('$tz', ...)=$time with TZ set");
        is($ENV{TZ}, "Europe/Berlin", "ENV{TZ} unchanged after tz_timelocal call");
    }
    {
        delete local $ENV{TZ};
        is(tz_timelocal($tz, @$tm), $time, "tz_timelocal('$tz', ...)=$time with TZ unset");
        ok(!exists $ENV{TZ}, "ENV{TZ} unchanged after tz_timelocal call");
    }
}

