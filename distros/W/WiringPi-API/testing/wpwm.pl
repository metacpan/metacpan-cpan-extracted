#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';

use RPi::ADC::ADS;
use RPi::WiringPi::Constant qw(:all);
use WiringPi::API qw(:all);

my $adc = RPi::ADC::ADS->new;

my $p = 18;

wiringPiSetupGpio();

pin_mode($p, PWM_OUT);

pwm_write($p, 512);

say "m: " . get_alt($p);
say "s: " . read_pin($p);
say "a: " . $adc->volts;

pwm_write($p, 768);

say "m: " . get_alt($p);
say "s: " . read_pin($p);
say "a: " . $adc->volts;


# sleep 1;

pinMode($p, INPUT);

say "m: " . get_alt($p);
say "s: " . read_pin($p);
say "a: " . $adc->volts;


