use strict;
use warnings;
use Test::More 'no_plan';

use UUID::Object;

my $class = 'UUID::Object';

my $u;

$u = $class->create_from_hash({
    variant  => 2,
    version  => 1,
    time_hi  => 465,
    node     => '00:c0:4f:d4:30:c8',
});

$u->assign_with_hash({
    time_mid => 40365,
    time_low => 1806153744,
    clk_seq  => 180,
});

is( $u->as_string, '6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'hash' );

