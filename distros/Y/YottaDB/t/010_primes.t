use strict;
use warnings;

use Test::More tests => 1;
use YottaDB qw/:all/;

my $limit = 10_000;

y_set Primes => $_, 1 for(2..$limit);

for (my $i = 2; defined $i; $i = y_next Primes => $i) {
	for (my $j = $i * $i; $j <= $limit; $j += $i) {
	    y_kill_tree Primes => $j;
	}
}

my $cnt = 0;
for (my $i = 2; defined $i; $i = y_next Primes => $i) {
   $cnt++;
}

ok ($cnt == 1229);

