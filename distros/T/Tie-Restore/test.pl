#########################

use Test;
BEGIN { plan tests => 3 };
use Tie::Restore;
ok(1); # If we made it this far, we're ok.

#########################

# a simple tie class
package TestTie;

sub FETCH {
	1;
}

sub STORE {}

# back to main
package main;

my $obj = bless [], 'TestTie';
tie $scalar, 'Tie::Restore', $obj;
ok($scalar); # make sure we get a 1

$scalar = 0;
ok($scalar); # make sure we still get a 1 (if we do, the tie obviously worked)
