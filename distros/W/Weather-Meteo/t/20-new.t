#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 2;
use Weather::Meteo;

isa_ok(Weather::Meteo->new(), 'Weather::Meteo', 'Creating Weather::Meteo object');
isa_ok(Weather::Meteo::new(), 'Weather::Meteo', 'Creating Weather::Meteo object');
# ok(!defined(Weather::Meteo::new()));
