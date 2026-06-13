use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:wiringPi :perl);

# V9: timing/scheduling wrappers - delay, delayMicroseconds (delay_microseconds),
# millis, micros, piMicros64 (pi_micros64), piHiPri (pi_hi_pri).

BEGIN {
    if (! $ENV{RPI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

WiringPi::API::wiringPiSetup();

for my $sub (qw(delay delay_microseconds millis micros pi_micros64 pi_hi_pri)){
    ok(WiringPi::API->can($sub), "$sub is defined/exported");
}

# millis() is monotonic, and a delay() of 50ms must advance it by >= ~40ms
my $start = millis();
like $start, qr/^\d+$/, "millis() returns an integer ($start)";

delay(50);

my $end = millis();
cmp_ok $end, '>=', $start + 40, "delay(50) advanced millis() by >= 40ms ($start -> $end)";

# micros() / pi_micros64() return positive integers
my $us = micros();
like $us, qr/^\d+$/, "micros() returns an integer ($us)";

my $us64 = pi_micros64();
like $us64, qr/^\d+$/, "pi_micros64() returns an integer ($us64)";
cmp_ok $us64, '>', 0, "pi_micros64() > 0";

# delay_microseconds() just needs to run cleanly
eval { delay_microseconds(100); };
is $@, '', "delay_microseconds(100) ran without error";

# pi_hi_pri() returns 0 on success or -1 on failure (non-root); either is valid
my $pri = pi_hi_pri(0);
like $pri, qr/^-?\d+$/, "pi_hi_pri(0) returns an integer ($pri)";
ok(($pri == 0 || $pri == -1), "pi_hi_pri(0) returned 0 (ok) or -1 (no privilege)");

done_testing();
