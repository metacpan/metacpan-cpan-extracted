#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN { push @INC, "t" } # need to have access to LimitTest.pm 

use Test::More tests => 9;

use_ok("version::Limit");

eval "use LimitTest 0.000";
like($@, qr/constructor syntax/,
    "bottom of first range matches");

eval "use LimitTest 0.001";
like($@, qr/constructor syntax/,
    "middle of first range matches");

eval "use LimitTest 1.0";
ok(!$@, "top of first range doesn't match");

eval "use LimitTest 1.001001";
ok(!$@, "Between ranges doesn't match");

eval "use LimitTest 2.002004";
like($@, qr/frobniz method croaks/,
    "bottom of second range matches");

eval "use LimitTest 2.002100";
like($@, qr/frobniz method croaks/,
    "middle of second range matches");

eval "use LimitTest 2.003001";
ok(!$@, "top of second range doesn't match");

eval "use LimitTest 5.000";
like($@, qr/version 5 required/,
    "normal 'requested version too high' method works");
