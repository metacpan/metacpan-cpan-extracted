use Test::More tests => 6;

use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;

use Weather::Bug::Quantity;

my $null_quant = Weather::Bug::Quantity->new(
    -value => '--',
    -units => q{"}
);
quantity_ok( $null_quant, 'Null from --', { null=>1, units=>'in', str=>'N/A' } );

my $null_quant2 = Weather::Bug::Quantity->new(
    -value => 'N/A',
    -units => 'ft'
);
quantity_ok( $null_quant2, 'Null from --', { null=>1, units=>'ft', str=>'N/A' } );

my $null_quant3 = Weather::Bug::Quantity->new(
    -value => 'n/a',
    -units => 'm'
);
quantity_ok( $null_quant3, 'Null from n/a', { null=>1, units=>'m', str=>'N/A' } );

my $a = Weather::Bug::Quantity->new(
    -value => '2',
    -units => q{"}
);
quantity_ok( $a, '2 inches', { value=>2, units=>'in', str=>'2 in' } );

my $b = Weather::Bug::Quantity->new(
    -value => '15',
    -units => 'mph'
);
quantity_ok( $b, '15 mph', { value=>15, units=>'mph', str=>'15 mph' } );

my $c = Weather::Bug::Quantity->new(
    -value => '-5.5',
    -units => 'm'
);
quantity_ok( $c, 'negative quantity', { value=>-5.5, units=>'m', str=>'-5.5 m' } );

