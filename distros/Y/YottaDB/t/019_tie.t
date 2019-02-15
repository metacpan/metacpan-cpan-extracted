use warnings;

use Test::More;
use YottaDB "y_get";
use YottaDB::Tie;

plan tests => 3;

tie my %h, YottaDB::Tie, "a", 0, 1, 2, 3;

$h{"three"} = 3;
$h{"four"} = 4;

ok("3" eq y_get "a", 0, 1, 2, 3, "three");
ok( "fourthree" eq join "", keys %h);
ok( "43" eq join "", values %h);
