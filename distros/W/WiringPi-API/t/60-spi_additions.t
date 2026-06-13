use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:wiringPi :perl);

# V15: SPI additions - wiringPiSPIGetFd (spi_get_fd), wiringPiSPISetupMode
# (spi_setup_mode), wiringPiSPIClose (spi_close).
#
# Exercises exports + argument guards (which croak before touching the SPI
# device, so no hardware/enabled-bus is required). Real transfers need the SPI
# bus enabled and a device wired up.

BEGIN {
    if (! $ENV{RPI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

for my $sub (qw(wiringPiSPIGetFd wiringPiSPISetupMode wiringPiSPIClose
                spi_get_fd spi_setup_mode spi_close)){
    ok(WiringPi::API->can($sub), "$sub is defined/exported");
}

# channel guards (0 or 1 only)
eval { spi_get_fd(5) };  like $@, qr/0 or 1/, "spi_get_fd() rejects channel 5";
eval { spi_get_fd() };   like $@, qr/0 or 1/, "spi_get_fd() rejects missing channel";
eval { spi_close(2) };   like $@, qr/0 or 1/, "spi_close() rejects channel 2";
eval { spi_close() };    like $@, qr/0 or 1/, "spi_close() rejects missing channel";
eval { spi_setup_mode(9, 1_000_000, 0) }; like $@, qr/0 or 1/, "spi_setup_mode() rejects channel 9";

# spi_setup_mode required-param guards
eval { spi_setup_mode(0) };           like $@, qr/speed/, "spi_setup_mode() needs \$speed";
eval { spi_setup_mode(0, 1_000_000) }; like $@, qr/mode/,  "spi_setup_mode() needs \$mode";

done_testing();
