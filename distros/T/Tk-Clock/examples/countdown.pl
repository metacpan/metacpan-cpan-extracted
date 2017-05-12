#!/pro/bin/perl

use Tk;
use Tk::Clock;

my $m = MainWindow->new;
my $c = $m->Clock (-background => "Black")->pack (-expand => 1, -fill => "both");
$c->config (
    useDigital	=> 0,
    useAnalog	=> 1,
    handColor	=> "White",
    secsColor	=> "Red",
    tickColor	=> "White",
    tickFreq	=> 1,
    tickDiff	=> 1,
    handCenter	=> 1,
    countDown	=> time,
    anaScale	=> 500,
    );
$c->config (anaScale => 0); # Allow resize

MainLoop;
