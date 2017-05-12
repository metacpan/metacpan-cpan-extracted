use warnings;
use strict;

use WiringPi::API;

my $core = WiringPi::API->new;

$core->pin_mode(1, 1);

print $core->get_alt(1);

$core->pwm_write(1, 500);

sleep 5;
