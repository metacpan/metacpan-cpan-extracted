use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:perl);

# pin_mode_alt() range validation. The Broadcom SoC (Pi 0-4) accepts a 3-bit
# function select (0-7); the RP1 chip on the Pi 5 adds ALT6-ALT8 (8-10), so the
# accepted range is widened there. Only the croak (out-of-range) boundary is
# exercised here - the success path writes real pin hardware.

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

WiringPi::API::wiringPiSetup();

ok(WiringPi::API->can('pin_mode_alt'), "pin_mode_alt() is defined/exported");

# The valid upper bound depends on the SoC: 10 on the Pi 5 (RP1), else 7.
my $max = pi_rp1_model() ? 10 : 7;

# One past the bound always croaks, and the message reports the live range.
eval { pin_mode_alt(0, $max + 1) };
like $@, qr/pin_mode_alt\(\) requires 0-$max as a param/,
    "pin_mode_alt() rejects $max + 1 (above the $max max) for this board";

# A negative value is always out of range.
eval { pin_mode_alt(0, -1) };
like $@, qr/pin_mode_alt\(\) requires 0-$max as a param/,
    "pin_mode_alt() rejects a negative \$alt";

# On a non-RP1 board, the RP1-only ALT6 value (8) must be rejected; on a Pi 5
# it is in range (so we do not write it here, just assert it is not rejected).
SKIP: {
    skip "Pi 5 (RP1) accepts ALT6-ALT8", 1 if pi_rp1_model();
    eval { pin_mode_alt(0, 8) };
    like $@, qr/pin_mode_alt\(\) requires 0-7 as a param/,
        "pin_mode_alt() rejects RP1-only ALT6 (8) on a non-Pi-5 board";
}

done_testing();
