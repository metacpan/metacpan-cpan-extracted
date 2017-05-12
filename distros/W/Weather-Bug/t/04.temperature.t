use Test::More tests => 7;

use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;

use Weather::Bug::Temperature;

my $null_temp = Weather::Bug::Temperature->new(
    -value => '--',
    -units => '&deg;C'
);

temperature_ok( $null_temp, 'Null Temperature',
    { null => 1, str => 'N/A' }
);

my $c_temp = Weather::Bug::Temperature->new(
    -value => '22',
    -units => '&deg;C'
);
temperature_ok( $c_temp, 'C Temp',
    { is_SI => 1, f => 71, c => 22, str => '22 C' }
);

$c_temp->is_SI( 0 );
temperature_ok( $c_temp, 'C Temp, changed',
    { is_SI => 0, f => 71, c => 22, str => '71 F' }
);

my $f_temp = Weather::Bug::Temperature->new(
    -value => '85',
    -units => '&deg;F'
);
temperature_ok( $f_temp, 'F Temp',
    { is_SI => 0, f => 85, c => 29, str => '85 F' }
);

$f_temp->is_SI( 1 );
temperature_ok( $f_temp, 'F Temp, changed',
    { is_SI => 1, f => 85, c => 29, str => '29 C' }
);

my $c_temp2 = Weather::Bug::Temperature->new(
    -value => '22.3',
    -units => '&deg;C'
);
temperature_ok( $c_temp2, 'C Temp2',
    { is_SI => 1, f => 72.1, c => 22.3, str => '22.3 C' }
);

my $f_temp2 = Weather::Bug::Temperature->new(
    -value => '85.2',
    -units => '&deg;F'
);
temperature_ok( $f_temp2, 'F Temp2',
    { is_SI => 0, f => 85.2, c => 29.6, str => '85.2 F' }
);

