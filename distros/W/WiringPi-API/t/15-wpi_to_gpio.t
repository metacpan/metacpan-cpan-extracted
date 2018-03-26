use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:perl);

my $mod = 'WiringPi::API';

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

WiringPi::API::wiringPiSetup();

is wpi_to_gpio(29), 21, "wpi pin 40 is GPIO 21";
is wpi_to_gpio(0),  17, "wpi pin 0  is GPIO 17";
is wpi_to_gpio(24), 19, "wpi pin 24 is GPIO 19";
is wpi_to_gpio(21),  5, "wpi pin 21 is GPIO 5";
is wpi_to_gpio(1),  18, "wpi pin 1  is GPIO 18";
is wpi_to_gpio(25), 26, "wpi pin 25 is GPIO 26";

done_testing();
