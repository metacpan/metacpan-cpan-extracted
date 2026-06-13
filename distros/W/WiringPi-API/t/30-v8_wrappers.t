use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:perl);

# V8: Perl wrappers newly surfaced for XS subs that previously had no Perl layer
# (softPwm*, piLock/piUnlock, digitalReadByte(2), digitalWriteByte(2)).

BEGIN {
    if (! $ENV{RPI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

WiringPi::API::wiringPiSetup();

my @wrappers = qw(
    soft_pwm_create soft_pwm_write soft_pwm_stop
    pi_lock pi_unlock
    digital_read_byte digital_read_byte2
    digital_write_byte digital_write_byte2
);

# all are defined and exported
for my $sub (@wrappers){
    ok(WiringPi::API->can($sub), "$sub is defined/exported");
}

# pi_lock / pi_unlock are pure software mutexes (no hardware) - exercise for real
eval {
    pi_lock(0);
    pi_unlock(0);
};
is $@, '', "pi_lock(0)/pi_unlock(0) round-trip without error";

# NOTE: digital_read_byte(2) / digital_write_byte(2) are intentionally NOT
# invoked here. On a Raspberry Pi 5, wiringPi declares these byte-bank ops
# unsupported and calls exit(1), which would abort the whole test process. The
# wrappers are verified above via can(); runtime exercise belongs on a board
# where wiringPi supports them (see Backlog B9).

done_testing();
