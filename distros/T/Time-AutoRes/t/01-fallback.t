#!/usr/bin/perl -w
#^^^^^^^^^^^^^^^^^ Just to make my editor use syntax highlighting

package Time::AutoRes::test;

use strict;
use warnings;

use Test::More 'tests' => 22;

use Test::Without::Module qw(Time::HiRes);

use Time::AutoRes qw(time sleep);

my ($t0, $tdelta);

#diag "Sleeping for 0 or 1 second 20 times...";

$t0 = time();
for (1..10) {
    my $d = sleep(0.5);
    like( $d, qr/^[01]$/, "sleep() return val (iteration $_)" );
    $d = Time::AutoRes::sleep(0.5);
    like( $d, qr/^[01]$/, "Time::AutoRessleep() return val (iteration $_)" );
}
$tdelta = time() - $t0;

#diag "Total elapsed time: $tdelta seconds (should average 10)";

#diag "Warning: This test will fail about once in 2^19 runs";
ok( $tdelta >  1, 'total elapsed time > 1'  );

#diag "Warning: This test will fail about once in 2^19 runs";
ok( $tdelta < 19, 'total elapsed time < 19' );

