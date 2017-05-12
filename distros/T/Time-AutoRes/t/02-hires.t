#!/usr/bin/perl -w
#^^^^^^^^^^^^^^^^^ Just to make my editor use syntax highlighting

package Time::AutoRes::test;

use strict;
use warnings;

use Test::More 'tests' => 22;

use Time::AutoRes qw(time sleep);

my ($t0, $tdelta);

#diag "Sleeping for 0 or 1 second 20 times...";

$t0 = time();
for (1..10) {
    my $d = sleep(0.5);
    cmp_ok( abs(0.5-$d), '<', 0.1, "sleep() return val (iteration $_)" );
    $d = Time::AutoRes::sleep(0.5);
    cmp_ok( abs(0.5-$d), '<', 0.1, "Time::AutoRes::sleep() return val (iteration $_)" );
}
$tdelta = time() - $t0;

#diag "Total elapsed time: $tdelta seconds (should average 10)";

#diag "Warning: This test will fail about once in 2^19 runs";
ok( $tdelta >  9, 'total elapsed time > 1'  );

#diag "Warning: This test will fail about once in 2^19 runs";
ok( $tdelta < 11, 'total elapsed time < 19' );

