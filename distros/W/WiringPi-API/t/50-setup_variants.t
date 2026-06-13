use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:wiringPi :perl :constants);

# V12: 3.3 setup variants (wiringPiSetupPinType / wiringPiSetupGpioDevice /
# wiringPiGpioDeviceGetFd) + WPIPinType constants. Physical-pin setup is
# intentionally unsupported: WPI_PIN_PHYS is not exported and the wrappers croak
# on anything other than WPI_PIN_BCM / WPI_PIN_WPI.

BEGIN {
    if (! $ENV{RPI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

# exports: C names + snake wrappers + constants
for my $sub (qw(wiringPiSetupPinType wiringPiSetupGpioDevice wiringPiGpioDeviceGetFd
                wiringpi_setup_pin_type wiringpi_setup_gpio_device
                wiringpi_gpio_device_get_fd WPI_PIN_BCM WPI_PIN_WPI)){
    ok(WiringPi::API->can($sub), "$sub is defined/exported");
}

# constant values
is WPI_PIN_BCM, 1, "WPI_PIN_BCM == 1";
is WPI_PIN_WPI, 2, "WPI_PIN_WPI == 2";

# WPI_PIN_PHYS must NOT be exposed (phys setup was removed)
ok(! WiringPi::API->can('WPI_PIN_PHYS'), "WPI_PIN_PHYS is not exported");

# the guard: croak on PHYS(3) / 0 / non-numeric / undef, with no warnings
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

for my $bad (3, 0, 'x', undef){
    my $label = defined $bad ? "'$bad'" : 'undef';
    eval { wiringpi_setup_pin_type($bad) };
    ok($@, "wiringpi_setup_pin_type($label) croaks");
    eval { wiringpi_setup_gpio_device($bad) };
    ok($@, "wiringpi_setup_gpio_device($label) croaks");
}

is scalar(@warnings), 0, "guards produced no warnings"
    or diag "warnings: @warnings";

# happy path: a single real setup via the new variant (WPI numbering)
my $rc = wiringpi_setup_pin_type(WPI_PIN_WPI);
like $rc, qr/^-?\d+$/, "wiringpi_setup_pin_type(WPI_PIN_WPI) returns an integer ($rc)";

done_testing();
