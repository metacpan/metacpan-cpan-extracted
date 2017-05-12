#!env perl

use strict;
use warnings;

use Test::More;
use Time::Local::TZ qw/:const tz_truncate/;

my @TESTS = (
    [ [ "UTC",                    0, TM_MIN  ],          0 ],
    [ [ "UTC",                    0, TM_HOUR ],          0 ],
    [ [ "UTC",                    0, TM_MDAY ],          0 ],
    [ [ "UTC",                    0, TM_MON  ],          0 ],
    [ [ "UTC",                    0, TM_YEAR ],          0 ],

    [ [ "Europe/Moscow",          0, TM_MIN  ],          0 ],
    [ [ "Europe/Moscow",          0, TM_HOUR ],          0 ],
    [ [ "Europe/Moscow",          0, TM_MDAY ],     -10800 ],
    [ [ "Europe/Moscow",          0, TM_MON  ],     -10800 ],
    [ [ "Europe/Moscow",          0, TM_YEAR ],     -10800 ],

    [ [ "UTC",           1461670850, TM_MIN  ], 1461670800 ],
    [ [ "UTC",           1461670850, TM_HOUR ], 1461668400 ],
    [ [ "UTC",           1461670850, TM_MDAY ], 1461628800 ],
    [ [ "UTC",           1461670850, TM_MON  ], 1459468800 ],
    [ [ "UTC",           1461670850, TM_YEAR ], 1451606400 ],

    [ [ "Europe/Moscow", 1461660050, TM_MIN  ], 1461660000 ],
    [ [ "Europe/Moscow", 1461660050, TM_HOUR ], 1461657600 ],
    [ [ "Europe/Moscow", 1461660050, TM_MDAY ], 1461618000 ],
    [ [ "Europe/Moscow", 1461660050, TM_MON  ], 1459458000 ],
    [ [ "Europe/Moscow", 1461660050, TM_YEAR ], 1451595600 ],

    [ [ "???",           1461670850, TM_MIN  ], 1461670800 ],
    [ [ "???",           1461670850, TM_HOUR ], 1461668400 ],
    [ [ "???",           1461670850, TM_MDAY ], 1461628800 ],
    [ [ "???",           1461670850, TM_MON  ], 1459468800 ],
    [ [ "???",           1461670850, TM_YEAR ], 1451606400 ],

    [ [                                      ], \undef ],
    [ [ "UTC"                                ], \undef ],
    [ [ "UTC", 1                             ], \undef ],
    [ [ "UTC", 1, 0                          ], \undef ],
    [ [ "UTC", 1, 6                          ], \undef ],
    [ [ "UTC", 1, 1, 1                       ], \undef ],
);

plan tests => @TESTS*4;


foreach my $t (@TESTS) {
    my ($data, $res) = @$t;
    {
        local $ENV{TZ} = "Europe/Berlin";
        if (ref $res) {
            ok(!eval { tz_truncate(@$data); 1 }, "tz_truncate(".join(', ', @$data).")");
        } else {
            is(tz_truncate(@$data), $res, "tz_truncate(".join(', ', @$data).") with TZ set");
        }
        is($ENV{TZ}, "Europe/Berlin", "ENV{TZ} unchanged after timelocal_tz call");
    }
    {
        delete local $ENV{TZ};
        if (ref $res) {
            ok(!eval { tz_truncate(@$data); 1 }, "tz_truncate(".join(', ', @$data).")");
        } else {
            is(tz_truncate(@$data), $res, "tz_truncate(".join(', ', @$data).") with TZ unset");
        }
        ok(!exists $ENV{TZ}, "ENV{TZ} unchanged after timelocal_tz call");
    }
}
