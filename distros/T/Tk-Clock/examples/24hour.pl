#!/pro/bin/perl

# A weird clock where the hour hand uses a 24-hour scale
use Tk;
use Tk::Clock;

my $m = MainWindow->new;
my $c = $m->Clock->pack (-expand => 1, -fill => "both");
$c->config (
    anaScale  => 250,
    ana24hour => 1,
    tickFreq  => 2.5,
    )->config (anaScale => 0);

MainLoop;
