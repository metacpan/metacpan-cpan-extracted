#!perl

use strict;
use warnings;

use Test::More tests => 31;

use Weather::NWS::NDFDgenByDay;

my $LAT = 42;
my $LON = -88;
my $START_DATE = scalar localtime; #now
my @NUM_DAYS = 1..7;

## Create Object

my $NDFDgenByDay = Weather::NWS::NDFDgenByDay->new();
ok($NDFDgenByDay, 'Object creation');

# Get Lists

my @FORMATS = $NDFDgenByDay->get_available_formats();
ok(@FORMATS, 'Fetch format list');

## Latitude and Longitude

ok($NDFDgenByDay->set_latitude($LAT)  == $LAT, 'Set latitude' );
ok($NDFDgenByDay->get_latitude()      == $LAT, 'Get latitude' );

ok($NDFDgenByDay->set_longitude($LON) == $LON, 'Set longitude');
ok($NDFDgenByDay->get_longitude()     == $LON, 'Get longitude');

ok($NDFDgenByDay->get_longitude() != $NDFDgenByDay->get_latitude(), 
   'Cross lat/lon'
);

## Formats

for my $format (@FORMATS) {
  ok($NDFDgenByDay->set_format($format) eq $format, "Set $format format");
  ok($NDFDgenByDay->get_format()        eq $format, "Get $format format");
}

eval { $NDFDgenByDay->set_format('Not A Format'); };
ok($@, "Set bogus format");

## Start Date

my $st;
ok($st = $NDFDgenByDay->set_start_date($START_DATE), 'Set start date');
ok($NDFDgenByDay->get_start_date() eq $st          , 'Get start date');

## Number of Days

for my $num (reverse @NUM_DAYS) {
    ok($num == $NDFDgenByDay->set_number_of_days($num), "Set $num days");
    ok($NDFDgenByDay->get_number_of_days() == $num    , "Set $num days");
}

eval {
    $NDFDgenByDay->set_number_of_days(0);
};
ok($@, 'Set too small of a day');

eval {
    $NDFDgenByDay->set_number_of_days(8);
};
ok($@, 'Set too large of a day');

eval{
 my $xml = $NDFDgenByDay->get_forecast_xml('Format'=>'Half-Day','Number of Days' => 2);
};
ok(not($@), 'Fetch forecast');
