use strict;
use warnings;

use Test::More;
use WiringPi::API qw(bmp180_temp bmp180_pressure);

# HW-free: the BMP180 unit conversion lives in the Perl wrappers (the XS
# bmp180Temp/bmp180Pressure just analogRead()). We stub the XS reads with a
# known raw value and assert the conversion math - no I2C, no sensor.

{
    no warnings 'redefine';
    # Raw temp 250 -> 25.0 C -> 77.0 F
    local *WiringPi::API::bmp180Temp     = sub { 250 };
    # Raw pressure 101325 -> 1013.25 kPa
    local *WiringPi::API::bmp180Pressure = sub { 101325 };

    is bmp180_temp(0),      77,      "bmp180_temp default (F): 250 -> 25C -> 77F";
    is bmp180_temp(0, 'f'), 77,      "bmp180_temp('f'): 77F";
    is bmp180_temp(0, 'c'), 25,      "bmp180_temp('c'): 25C";
    is bmp180_pressure(0),  1013.25, "bmp180_pressure: 101325 -> 1013.25 kPa";
}

done_testing();
