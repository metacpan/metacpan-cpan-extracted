#!perl
use strict;
use Weather::WeatherGov;
use Data::Dumper;

our $VERSION = '0.03';

my $w = Weather::WeatherGov->new(
);
print Dumper
    $w->forecast(latitude =>39.7456, longitude => -97.0892 );
