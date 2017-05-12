#!/pro/bin/perl

# A default clock the starts at 1.5 time original size and is scalable
use Tk;
use Tk::Clock;

my $m = MainWindow->new;
my $c = $m->Clock->pack (-expand => 1, -fill => "both");
$c->config (anaScale  => 150)->config (anaScale => 0);

MainLoop;
