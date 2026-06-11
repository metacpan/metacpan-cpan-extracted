use strict;
use warnings;

use Test::More;
use WiringPi::API qw(phys_to_wpi physPinToWpi);

# F21 bounds-check coverage. physPinToWpi() just indexes a static 64-entry
# map (no wiringPi setup or hardware needed), so this runs anywhere.

# In-range, valid mappings (from phys_wpi_map)
is(phys_to_wpi(11), 0,  'phys 11 -> wpi 0');
is(phys_to_wpi(12), 1,  'phys 12 -> wpi 1');

# In-range physical pin with no wiringPi equivalent -> -1 sentinel
is(phys_to_wpi(1),  -1, 'phys 1 (no wpi pin) -> -1');

# Out-of-range must return -1, NOT read out of bounds (the F21 fix)
is(phys_to_wpi(-1),   -1, 'phys_to_wpi(-1) -> -1');
is(phys_to_wpi(64),   -1, 'phys_to_wpi(64) (one past end) -> -1');
is(phys_to_wpi(5000), -1, 'phys_to_wpi(5000) -> -1');

# The raw XS function guards too
is(physPinToWpi(-5),  -1, 'physPinToWpi(-5) -> -1');
is(physPinToWpi(64),  -1, 'physPinToWpi(64) -> -1');
is(physPinToWpi(999), -1, 'physPinToWpi(999) -> -1');

# Non-integer / undef handled by the Perl guard (no warning, no crash)
is(phys_to_wpi(undef), -1, 'phys_to_wpi(undef) -> -1');

done_testing();
