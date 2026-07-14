use strict;
use warnings;

use Test::More;
use WiringPi::API qw(spi_no_cs);

# HW-free: spi_no_cs()'s Perl validation croaks before any SPI, and with no
# SPI channel set up, spiNoCS()'s fd check (XS) croaks before any ioctl - so
# nothing here needs an open SPI bus. We never make a call that would reach
# the hardware.

eval { spi_no_cs(2, 1) };
like $@, qr/channel param must be 0 or 1/, "spi_no_cs: bad channel croaks";

eval { spi_no_cs(undef, 1) };
like $@, qr/channel param must be 0 or 1/, "spi_no_cs: undef channel croaks";

eval { spi_no_cs(0) };
like $@, qr/requires a \$state param/, "spi_no_cs: missing state croaks";

eval { WiringPi::API::spiNoCS(0, 1) };
like $@, qr/not set up/, "spiNoCS: unopened channel croaks (XS fd check)";

eval { WiringPi::API::spiNoCS(1, 0) };
like $@, qr/not set up/, "spiNoCS: unopened channel 1 croaks (XS fd check)";

done_testing();
