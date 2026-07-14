use strict;
use warnings;

use Test::More;
use WiringPi::API qw(phys_to_gpio wpi_to_gpio);

# F5 bounds-check coverage. phys_to_gpio()/wpi_to_gpio() forward to the wiringPi
# library lookups (64-entry tables); without a guard, an out-of-range index is
# an OOB read. The Perl guard (mirroring phys_to_wpi) returns the -1 "no such
# pin" sentinel instead. The guard fires before the library call, so these run
# anywhere - no wiringPi setup, no hardware. (In-range mappings need setup, so
# we only assert the out-of-range guard here.)

for my $fn_name (qw(phys_to_gpio wpi_to_gpio)) {
    my $fn = WiringPi::API->can($fn_name);

    is $fn->(-1),    -1, "$fn_name(-1) -> -1 (no OOB read)";
    is $fn->(64),    -1, "$fn_name(64) (one past end) -> -1";
    is $fn->(5000),  -1, "$fn_name(5000) -> -1";
    is $fn->(undef), -1, "$fn_name(undef) -> -1 (no warning)";
    is $fn->('x'),   -1, "$fn_name('x') -> -1 (non-integer)";
}

done_testing();
