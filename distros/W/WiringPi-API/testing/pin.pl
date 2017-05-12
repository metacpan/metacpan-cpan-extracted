#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';


use WiringPi::API qw(:all);
use RPi::WiringPi::Constant qw(:all);

my $p = 18;

wiringPiSetupGpio();

pinMode($p, OUTPUT);
digitalWrite($p, HIGH);

say "m: " . get_alt($p);
say "s: " . read_pin($p);

# sleep 1;

pinMode($p, INPUT);

say "m: " . get_alt($p);
say "s: " . read_pin($p);
