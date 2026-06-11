use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:perl);

# V1 board-map precheck / F9 gate.
#
# Validates the custom phys_wpi_map (API.h) against wiringPi's own pin tables on
# whatever board this runs on (notably Pi5/RP1, where upstream cautions against
# wpi/phys mapping). Ground truth is wiringPi itself: for every physical header
# pin our map claims maps to wiringPi pin w, the two native translations must
# agree on the BCM gpio --
#
#     wpi_to_gpio(phys_to_wpi(p)) == phys_to_gpio(p)
#
# A mismatch means our hardcoded table disagrees with the installed wiringPi for
# this board and must be fixed before the upgrade proceeds.

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

WiringPi::API::wiringPiSetup();

my @mapped;

for my $phys (1 .. 40){
    my $wpi = phys_to_wpi($phys);

    # -1 is the map's "no wiringPi pin" sentinel (power / ground / ID pins)
    next if ! defined $wpi || $wpi < 0;

    push @mapped, $phys;

    my $gpio_via_wpi  = wpi_to_gpio($wpi);
    my $gpio_via_phys = phys_to_gpio($phys);

    is $gpio_via_wpi, $gpio_via_phys,
        "phys $phys -> wpi $wpi -> BCM $gpio_via_wpi matches phys->BCM $gpio_via_phys";
}

cmp_ok scalar(@mapped), '>=', 26,
    "at least the 26 standard GPIO header pins are mapped (got " . scalar(@mapped) . ")";

done_testing();
