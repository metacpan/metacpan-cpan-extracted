use warnings;
use strict;
use feature 'say';

use Time::HiRes qw(usleep);
use WiringPi::API qw(:all);

# script to blink all 20 shift register pins

my $rand;

if ($ARGV[0]){
    $rand = 1;
}

my $c = 1;

$SIG{INT} = sub {
    $c = 0;
};

setup_gpio();

my $data   = 5;
my $clk    = 6;
my $latch = 13;

shift_reg_setup(100, 20, $data, $clk, $latch);

write_pin(119, 1);

sleep 1;

write_pin(119, 0);
