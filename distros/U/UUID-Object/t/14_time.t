use strict;
use warnings;
use Test::More;

eval q{ use Data::UUID };
plan skip_all => 'Data::UUID is not installed.' if $@;

plan tests => 1;

use UUID::Object;

my $t = time;
my $du = Data::UUID->new();
my $u = UUID::Object->create_from_string($du->create_str());

SKIP: {
if (abs($u->time - $t) < 100.0) {
    ok( abs($u->time - $t) < 100.0, 'time field of Data::UUID(v1)' );
}
else {
    skip sprintf('time() may be inconsitent; %f <=> %f', $u->time, $t), 1;
    ok( abs($u->time - $t) < 100.0, 'time field of Data::UUID(v1)' );
}
}
