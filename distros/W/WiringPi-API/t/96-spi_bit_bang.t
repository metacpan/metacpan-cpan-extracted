use strict;
use warnings;

use Test::More;
use WiringPi::API qw(spi_bit_bang);

# HW-free: every case fails validation (Perl or XS) before the frame loop
# would touch a pin, so no wiringPi setup or wiring is needed. We never make
# a valid call (that would toggle GPIO). spiBitBang() validates its entire
# byte buffer before asserting chip select, so the XS range checks are also
# safe to exercise here.

eval { spi_bit_bang(undef, 10, 9, 8, [0], 1) };
like $@, qr/clk param/, "spi_bit_bang: missing clk croaks";

eval { spi_bit_bang(11, -2, 9, 8, [0], 1) };
like $@, qr/mosi, miso and cs/, "spi_bit_bang: bad mosi croaks";

eval { spi_bit_bang(11, 10, 9, 8, 'not_a_ref', 1) };
like $@, qr/must be an array reference/, "spi_bit_bang: non-aref data croaks";

eval { spi_bit_bang(11, 10, 9, 8, [0, 1], 1) };
like $@, qr/\$len param count/, "spi_bit_bang: \@data/\$len mismatch croaks";

eval { spi_bit_bang(11, 10, 9, 8, [0], 1, 4) };
like $@, qr/mode param must be 0-3/, "spi_bit_bang: bad mode croaks";

eval { spi_bit_bang(11, 10, 9, 8, [0], 1, 0, -5) };
like $@, qr/delay_us param/, "spi_bit_bang: negative delay croaks";

eval { WiringPi::API::spiBitBang(11, 10, 9, 8, [256], 1, 0, 0) };
like $@, qr/out of range/, "spiBitBang: byte > 255 croaks (XS range check)";

eval { WiringPi::API::spiBitBang(11, 10, 9, 8, [undef], 1, 0, 0) };
like $@, qr/undefined/, "spiBitBang: undef byte croaks (XS check)";

done_testing();
