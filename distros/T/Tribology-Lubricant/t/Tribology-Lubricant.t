# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tribology-Lubricant.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Try::Tiny;

use constant {
    LABEL   => 0,
    VISC40  => 1,
    VISC100 => 2,
    VI      => 3,
    M       => 4,
    VTC     => 5
};

use Test::More ("no_plan");
use lib "./lib";

BEGIN { use_ok('Tribology::Lubricant') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @table_31 = (
    [ "Naphthenic spindle oil", 30,  4.24, 40,  "4.05", "0.847" ],
    [ "Paraffinic spindle oil", 30,  5.23, 105, "3.68", "0.819" ],
    [ "Medium solvent extract", 120, 8.0,  -50, "4.51", "0.939" ],
    [ "Medium polyglycol",      120, 20.9, 200, "2.53", "0.827" ],
    [ "Medium silicone oil",    120, 50.0, 424, "1.14", "0.583" ],
    [ "Multigrade motor oil",   70,  11.1, 165, "2.82", "0.841" ],
    [ "Ester oil",              30,  5.81, 140, "3.40", "0.806" ]
);

foreach my $data (@table_31) {
    my $lub = Tribology::Lubricant->new(
        {   label  => $data->[LABEL],
            visc40 => $data->[VISC40]
        }
    );

    ok( ref $lub, ref $lub );

    is( $lub->visc( 100, "$data->[VISC100]" ), $data->[VISC100] );
    is( $lub->label,     "$data->[LABEL]",   "Label = " . $lub->label );
    is( $lub->visc(40),  "$data->[VISC40]",  "visc \@40 = " . $data->[VISC40]);
    is( $lub->visc(100), "$data->[VISC100]", "visc \@100 = " . $data->[VISC100] );
    ok( $lub->vi,  "VI = " . $lub->vi );
    ok( $lub->m,   "m = " . $lub->m );
    ok( $lub->vtc, "VTC = " . $lub->vtc );

    foreach my $t ( -100 .. 100 ) {
        my $cst = $lub->visc($t);
        ok( $cst, "visc \@ $t = $cst" );
    }
}

my $lub = Tribology::Lubricant->new( { label => "Hypothetical lubricant" } );

ok( ref $lub );
is( $lub->label, "Hypothetical lubricant", $lub->label );

my $success = try {
    $lub->vi;
};

ok( !$success, "not enough calibration points" );

$lub->visc( 40,  30 );
$lub->visc( 100, 5.23 );

ok($lub->vtc );

$lub = Tribology::Lubricant->new;

$lub->visc( 40, 5 );
$lub->visc( 60, 2 );
is( $lub->vtc, "0.8", "vtc when 40/100 calibratioin points are missing is 0.8 (default)" );

####################### L, H tests ###############################
#
#

$lub->visc(100, 8.86);
my ($L, $H) = $lub->LH();
is($L, "119.94", "L=119.94");
is($H, "69.48", "H=69.48");

$lub->visc(100, 70);
($L, $H) = $lub->LH();
is($L, 4905, "L=4905");
is($H, 1558, "H=1558");

$lub->visc(100, 71);
my ($L_71, $H_71) = $lub->LH();

ok($L_71 > $L, "L71 > L70");
ok($H_71 > $H, "H71 > H70");

$lub->visc(100, 5.05);
$lub->visc(40, 22.83);

is($lub->vi, 156, "VI=156");

$lub->visc(100, 7.80);
$lub->visc(40, 53.47);

is($lub->vi, 111, "VI=111");


