use warnings;
use strict;

use Test::More;
use YottaDB qw(y_get y_set y_data);
use YottaDB::Tie;

plan tests => 11;

tie my %h, "YottaDB::Tie", "a", 0, 1, 2, 3;

$h{"three"} = 3;
$h{"four"} = 4;

ok("3" eq y_get "a", 0, 1, 2, 3, "three");
ok( "fourthree" eq join "", keys %h);
ok( "43" eq join "", values %h);

ok(exists $h{three});

ok(!exists $h{undefined});
ok(!defined $h{undefined});

%h = (one => 1, two => 2);
y_set "a", 0, 1, 2, 3, 4, 5, 6;
ok( "onetwo" eq join "", keys %h);

untie %h;

y_set "h", 0, 0;
y_set "h", 1, 1;
y_set "h", 2, 2, 2;
y_set "h", 3, 3;
y_set "h", 3, 3, 3;
y_set "h", 3, 3, 3, 4;

tie %h, "YottaDB::Tie", "h";

ok("013" eq join "", keys %h);

%h = ();

ok("" eq join "", keys %h);
ok(10 == y_data "h", 2);
ok(4 == y_get "h", 3, 3, 3);
