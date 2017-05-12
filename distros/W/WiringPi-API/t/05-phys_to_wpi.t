use strict;
use warnings;

use Data::Dumper;
use Test::More;

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

BEGIN { use_ok('WiringPi::API') };

my $mod = 'WiringPi::API';

my %map;

for (0..63){
    $map{$_} = WiringPi::API::phys_to_wpi($_);
}

is $map{40}, 29, "phys pin 40 == wpi 29";
is $map{0},  -1, "phys pin 0 is -1";
is $map{2},  -1, "phys pin 2 is -1";
is $map{8},  15, "phys pin 8 == wpi 15";
is $map{16},  4, "phys pin 16 == wpi 4";

done_testing();
