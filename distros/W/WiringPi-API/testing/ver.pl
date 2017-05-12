use warnings;
use strict;
use feature 'say';

use Time::HiRes qw(usleep);
use WiringPi::API qw(:all);

say wiringPiVersion();

my $x = 2.32 >= wiringPiVersion ? 1 : 0;

say $x;
