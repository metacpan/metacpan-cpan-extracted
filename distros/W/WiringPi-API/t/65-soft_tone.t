use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:wiringPi :perl);

# V16: softTone wrappers - softToneCreate (soft_tone_create), softToneStop
# (soft_tone_stop), softToneWrite (soft_tone_write).
#
# These drive a hardware tone (and spawn a software thread on the pin), so they
# are verified via can()/export rather than invoked on an unknown-wired board.
# (wiringPi's softServo is not in the 3.18 shared library, so it is not wrapped.)

BEGIN {
    if (! $ENV{RPI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

WiringPi::API::wiringPiSetup();

for my $sub (qw(softToneCreate softToneStop softToneWrite
                soft_tone_create soft_tone_stop soft_tone_write)){
    ok(WiringPi::API->can($sub), "$sub is defined/exported");
}

# softServo must NOT have leaked in (absent from the wiringPi lib)
ok(! WiringPi::API->can('softServoSetup'), "softServoSetup not wrapped (absent from lib)");
ok(! WiringPi::API->can('soft_servo_setup'), "soft_servo_setup not wrapped");

done_testing();
