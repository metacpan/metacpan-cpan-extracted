use warnings;
use strict;
use feature 'say';

use WiringPi::API qw(:all);

my $base = 200;

bmp180Setup($base);

say "temp r: " .analogRead(200);
#say analog_read(201);

say "temp f: " .bmp180_temp(200);
say "temp c: " .bmp180_temp(200, 'c');

say "pres k: " .bmp180_pressure(201);
