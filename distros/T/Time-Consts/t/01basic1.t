use Test::More tests => 7;
BEGIN { use_ok('Time::Consts') };

#########################

use Time::Consts qw/
    MSEC
    SEC
    MIN
    HOUR
    DAY
    WEEK
/;

ok(MSEC == 1 / 1000, "Default base (SEC)");
ok(SEC  == 1);
ok(MIN  == 60);
ok(HOUR == 60 * 60);
ok(DAY  == 60 * 60 * 24);
ok(WEEK == 60 * 60 * 24 * 7);
