# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Finance::BDT') };

my @y = (0, 0.0283, 0.029, 0.0322, 0.0401, 0.0435, 0.0464, 0.0508, 0.0512);        ## YTM on strips
my ($r, $d, $A) = Finance::BDT::bdt( -yields => \@y, -epsilon => 0.00001, -volatility => 0.20 );
ok(abs($r->[2][1] - 0.037196474770821) < 0.000001, "short rates");
ok(abs($d->[3][2] - 0.928649759175238) < 0.000001, "discount prices");
ok(abs($A->[1][0] - 0.486048347022154) < 0.000001, "asset prices");


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

