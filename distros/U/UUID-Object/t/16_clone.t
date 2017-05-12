use strict;
use warnings;
use Test::More tests => 5;

use UUID::Object;

my $class = 'UUID::Object';

my $u0 = $class->create_from_string('6ba7b810-9dad-11d1-80b4-00c04fd430c8');
my $u1 = $class->create_from_string('6ba7b810-9dad-11d1-80b4-00c04fd430c8');

is( $u1, $u0, 'base' );

my $u2 = $u1->clone();
is( $u2, $u1, 'cloned' );

$u2->time_mid(1234);
is( $u2->time_mid, 1234, 'changed' );
ok( $u1->time_mid != 1234, 'changing cloned doesnt affect original' );
is( $u1, $u0, 'orignal keeps' );

