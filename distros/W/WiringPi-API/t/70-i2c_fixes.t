use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:perl);

# V18 (F1): i2c_read_word() now reads a 16-bit register (was wrongly 8-bit).
# V19 (F2): i2c_setup() accepts full decimal/hex addresses (was a single digit).
#
# The address-validation REJECTION paths croak before any device access, so they
# are hardware-free. Exercising an accepted address (and i2c_read_word) requires
# the standard /dev/i2c-1 bus enabled with a wired device; wiringPiI2CSetup
# aborts the process if the bus is absent, so those are gated / deferred to the
# downstream RPi::WiringPi i2c hardware suite (UPGRADE-3.18.md V33).

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

ok(WiringPi::API->can('i2c_read_word'), "i2c_read_word is defined");
ok(WiringPi::API->can('i2c_setup'),     "i2c_setup is defined");

# V19 rejection paths (no device touched)
eval { i2c_setup() };        like $@, qr/requires an \$addr/, "i2c_setup() croaks on missing addr";
eval { i2c_setup("foo") };   like $@, qr/integer or hex/,     "i2c_setup() croaks on non-numeric junk";
eval { i2c_setup("12g") };   like $@, qr/integer or hex/,     "i2c_setup() croaks on bad hex-ish junk";

# V19 acceptance: only runnable where the standard bus exists (else wiringPi
# aborts on open). Proves 0x48/72 are no longer rejected by the regex.
SKIP: {
    skip "standard I2C bus (/dev/i2c-1) not enabled", 2 unless -e '/dev/i2c-1';

    my $fd_dec = i2c_setup(72);
    cmp_ok $fd_dec, '>=', 0, "i2c_setup(72) accepted (fd $fd_dec)";

    my $fd_hex = i2c_setup("0x48");
    cmp_ok $fd_hex, '>=', 0, "i2c_setup('0x48') accepted (fd $fd_hex)";
}

done_testing();
