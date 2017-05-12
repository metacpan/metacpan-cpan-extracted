use strict;
use warnings;
use Test::More tests => 9;

use UUID::Object;

my $class = 'UUID::Object';

my $u = $class->create_from_string('6ba7b810-9dad-11d1-80b4-00c04fd430c8');

# getters
is( $u->variant, 2, 'variant' );
is( $u->version, 1, 'version' );
is( $u->time_hi, 465, 'time_hi' );
is( $u->time_mid, 40365, 'time_mid' );
is( $u->time_low, 1806153744, 'time_low' );
is( $u->clk_seq, 180, 'clk_seq' ),
is( uc($u->node), '00:C0:4F:D4:30:C8', 'node' );

# setters
$u = $class->new();

$u->variant(2);
$u->version(1);
$u->time_hi(465);
$u->time_mid(40365);
$u->time_low(1806153744);
$u->clk_seq(180);
$u->node('00:c0:4f:d4:30:c8');

is( $u->as_string, '6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'setter' );

# time
my $t = time;
$u->time($t);
is( $u->time, $t, 'time' );
