use Test::More tests => 7;
BEGIN { use_ok('Time::Consts') };

#########################

use Time::Consts qw/
    msec
    MSEC
    SEC
    MIN
    HOUR
    DAY
    WEEK
/;

ok(MSEC == 1, "MSEC as base");
ok(SEC  == 1000 * 1);
ok(MIN  == 1000 * 60);
ok(HOUR == 1000 * 60 * 60);
ok(DAY  == 1000 * 60 * 60 * 24);
ok(WEEK == 1000 * 60 * 60 * 24 * 7);
