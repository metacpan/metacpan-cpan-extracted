use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:wiringPi :perl);

# V10: wrappers for the previously-unimplemented setPadDrive / setPadDrivePin /
# pwmToneWrite / gpioClockSet.
#
# These actively drive hardware (pad drive strength, PWM tone output, GPIO clock
# output) and some may be unsupported on the Pi 5. They are therefore verified
# via can()/export here rather than invoked, to avoid disturbing whatever is (or
# isn't) wired to the board running the suite.

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

WiringPi::API::wiringPiSetup();

# C-name exports (:wiringPi)
for my $sub (qw(setPadDrive setPadDrivePin pwmToneWrite gpioClockSet)){
    ok(WiringPi::API->can($sub), "$sub (C export) is defined");
}

# snake_case wrappers (:perl)
for my $sub (qw(set_pad_drive set_pad_drive_pin pwm_tone_write gpio_clock_set)){
    ok(WiringPi::API->can($sub), "$sub (Perl wrapper) is defined/exported");
}

done_testing();
