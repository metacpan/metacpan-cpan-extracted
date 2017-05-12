use warnings;
use strict;

# connect phys pin 40 to ground via a switch,
# run the script, and press the button

use RPi::WiringPi::Constant qw(:all);
use WiringPi::API qw(:perl);

my $c = 1;
$SIG{INT} = sub {$c=0;};

setup_gpio();

set_interrupt(21, EDGE_FALLING, 'handler');

pin_mode(18, OUTPUT);

pin_mode(21, INPUT);
pull_up_down(21, PUD_UP);

my $x = 1;

while ($c){
    print "count: ". $x++ ." state: ". read_pin(21) ."\n";
    sleep 1;
}

pull_up_down(21, PUD_OFF);

pin_mode(18, INPUT);

sub handler {
    print "in edge fall interrupt handler...\n";
}

