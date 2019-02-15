use strict;
use warnings;

use Test::More tests => 1;
use YottaDB qw/:all/;

y_set "a", 1, 2, 3, 4, 5, 6, 1;
y_set "a", 1, 4, 3, 4, 5, 6, 2;
y_set "a", 1, 5, 3, 4, 5, 6, 3;
y_set "a", 2, 4;

my @r;
my $res = 0;

$res += y_get "a", @r while (@r = y_node_next "a", @r);

ok($res == 10);
