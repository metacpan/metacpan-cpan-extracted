#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Weather::Meteo') || print 'Bail out!';
}

require_ok('Weather::Meteo') || print 'Bail out!';

diag("Testing Weather::Meteo $Weather::Meteo::VERSION, Perl $], $^X");
