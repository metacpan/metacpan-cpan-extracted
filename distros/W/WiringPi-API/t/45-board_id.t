use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:wiringPi :perl);

# V11: board/identity helpers - piBoardId, piBoard40Pin, piRP1Model,
# getPinModeAlt, wiringPiGlobalMemoryAccess, wiringPiUserLevelAccess. These are
# read-only identity queries, safe to exercise on any board.

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

WiringPi::API::wiringPiSetup();

my @c    = qw(piBoardId piBoard40Pin piRP1Model getPinModeAlt
              wiringPiGlobalMemoryAccess wiringPiUserLevelAccess);
my @perl = qw(pi_board_id pi_board40_pin pi_rp1_model get_pin_mode_alt
              wiringpi_global_memory_access wiringpi_user_level_access);

for my $sub (@c, @perl){
    ok(WiringPi::API->can($sub), "$sub is defined/exported");
}

# pi_board_id() list context -> 5 integers
my @id = pi_board_id();
is scalar(@id), 5, "pi_board_id() returns 5 values in list context";
like $_, qr/^-?\d+$/, "pi_board_id() element '$_' is an integer" for @id;

# pi_board_id() scalar context -> hashref with the documented keys
my $id = pi_board_id();
is ref($id), 'HASH', "pi_board_id() returns a hashref in scalar context";
ok(exists $id->{$_}, "pi_board_id() hashref has key '$_'")
    for qw(model rev mem maker over_volted);

# the simple integer-returning queries
like pi_board40_pin(), qr/^-?\d+$/, "pi_board40_pin() returns an integer";
like pi_rp1_model(),   qr/^-?\d+$/, "pi_rp1_model() returns an integer";
like get_pin_mode_alt(0), qr/^-?\d+$/, "get_pin_mode_alt(0) returns an integer";
like wiringpi_global_memory_access(), qr/^-?\d+$/,
    "wiringpi_global_memory_access() returns an integer";
like wiringpi_user_level_access(), qr/^-?\d+$/,
    "wiringpi_user_level_access() returns an integer";

done_testing();
