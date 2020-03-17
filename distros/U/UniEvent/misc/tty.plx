use 5.012;
use UniEvent;
use UniEvent::Tty;
use lib 't/lib';
use MyTest;

my $loop = UE::Loop->default;

my $tty_in = UE::Tty->new(0);
my $tty_out = UE::Tty->new(2);

$tty_in->read_start();
$tty_in->read_callback(sub {
    say "READ1";
});

my $t = UE::Timer->start(1, sub {
    say "epta";
    $tty_out->write("epta write\n", sub {
        say "WRITTEN @_";
    });
});

say "RUN LOOP";

$loop->run;
