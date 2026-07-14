use strict;
use warnings;

use Test::More;
use WiringPi::API qw(shift_reg_setup serial_gets lcd_init);

# HW-free: each of these validates its args and croaks before the XS/hardware
# call (sr595Setup / serialGets / lcdInit), so the rejection paths run anywhere.

# --- shift_reg_setup(pin_base, num_pins, data, clock, latch) ---

eval { shift_reg_setup('x', 8, 2, 3, 4) };
like $@, qr/\$pin_base must be an integer/, "shift_reg_setup: non-integer pin_base croaks";

eval { shift_reg_setup(100, 33, 2, 3, 4) };
like $@, qr/\$num_pins must be between 0 and 32/, "shift_reg_setup: num_pins > 32 croaks";

eval { shift_reg_setup(100, 8, 2, 3, 41) };
like $@, qr/valid GPIO pin numbers/, "shift_reg_setup: pin > 40 croaks";

eval { shift_reg_setup(100, 8, -1, 3, 4) };
like $@, qr/valid GPIO pin numbers/, "shift_reg_setup: pin < 0 croaks";

# --- serial_gets($fd, $nbytes) ---

eval { serial_gets(undef, 5) };
like $@, qr/requires the \$fd param/, "serial_gets: missing fd croaks";

eval { serial_gets(3, undef) };
like $@, qr/requires \$nbytes/, "serial_gets: missing nbytes croaks";

eval { serial_gets(3, 'x') };
like $@, qr/non-negative integer/, "serial_gets: non-integer nbytes croaks";

# --- lcd_init(%params): 14 required keys ---

eval { lcd_init() };
like $@, qr/'rows' is a required param/, "lcd_init: missing first required key croaks";

eval {
    lcd_init(
        rows => 2, cols => 16, bits => 4, rs => 1, strb => 2,
        d0 => 0, d1 => 0, d2 => 0, d3 => 0, d4 => 4, d5 => 5, d6 => 6,
        # d7 omitted
    );
};
like $@, qr/'d7' is a required param/, "lcd_init: missing d7 croaks";

done_testing();
