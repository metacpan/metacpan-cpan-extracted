use Test::More tests => 3;

use_ok('Tie::NetAddr::IP');

my %WhereIs;
tie %WhereIs, Tie::NetAddr::IP;

$WhereIs{"0.0.0.0/0"} = "Somewhere";

is($WhereIs{"127.0.0.1"}, "Somewhere");

%WhereIs = ();

ok(! exists $WhereIs{"127.0.0.1"});

untie %WhereIs;
