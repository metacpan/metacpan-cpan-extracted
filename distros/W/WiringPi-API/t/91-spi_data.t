use strict;
use warnings;

use Test::More;
use WiringPi::API qw(spi_data);

# HW-free: spi_data()'s Perl validation croaks before any SPI, and spiDataRW()'s
# per-byte 0-255 check (XS) croaks before wiringPiSPIDataRW() - so out-of-range
# bytes are caught without an open SPI bus. We never make a *valid* call (that
# would touch the bus), only assert the rejections.

eval { spi_data(2, [1], 1) };
like $@, qr/channel param must be 0 or 1/, "spi_data: bad channel croaks";

eval { spi_data(0, 'not_a_ref', 1) };
like $@, qr/must be an array reference/, "spi_data: non-arrayref data croaks";

eval { spi_data(0, [1, 2], 1) };
like $@, qr/must have \$len param count/, "spi_data: \@data/\$len mismatch croaks";

eval { spi_data(0, [256], 1) };
like $@, qr/out of range/, "spi_data: byte > 255 croaks (spiDataRW range check)";

eval { spi_data(0, [-1], 1) };
like $@, qr/out of range/, "spi_data: byte < 0 croaks (spiDataRW range check)";

done_testing();
