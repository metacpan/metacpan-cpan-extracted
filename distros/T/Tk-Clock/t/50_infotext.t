#!/pro/bin/perl

use strict;
use warnings;

use     Test::More;
require Test::NoWarnings;

BEGIN {
    use_ok ("Tk");
    use_ok ("Tk::Clock");
    }

my ($delay, $m) = $ENV{TK_TEST_LENGTH} || 1000;
unless ($m = eval { MainWindow->new  (-title => "clock") }) {
    diag ("No valid Tk environment");
    done_testing;
    exit 0;
    }

ok (my $c  = $m->Clock (-relief => "flat"), "base clock");
ok ($c->config (
    useAnalog	=> 1,
    useDigital	=> 1,
    dateFont	=> "{DejaVu Sans Mono} 11",
    timeFont	=> "{DejaVu Sans Mono} 11",
    infoFont	=> "{DejaVu Sans Mono} 11",
    textFont	=> "{DejaVu Sans Mono} 11",
    dateColor	=> "Blue",
    timeColor	=> "Red",
    infoColor	=> "Green",
    textColor	=> "Orange",
    handColor	=> "#ffe0e0",
    useSecHand	=> 0,
    tickColor	=> "Blue",
    tickDiff	=> 1,
    handCenter	=> 1,
    anaScale	=> 330,
    ), "base config ()");
$c->pack (-expand => 1, -expand => "both");

sub text { int rand 9000 };

my $ix = 15;
sub next_ix {
    my $use_dt = $ix & 010;
    my $use_tm = $ix & 004;
    my $use_if = $ix & 002;
    my $use_tx = $ix & 001;

    ok ($c->config (
	useInfo    => $use_if,
	useText    => $use_tx,
	dateFormat => $use_dt ? "yyyy-mm-dd" : " ",
	timeFormat => $use_tm ? "HH:MM:SS"   : " ",
	infoFormat => $use_if ? "Info"       : " ",
	textFormat => $use_tx ? \&text       : " ",
	), "config ($ix, $use_dt, $use_tm, $use_if, $use_tx)");
    $c->update;
    if ($ix--) {
	$c->after ($delay, \&next_ix);
	}
    else {
	$c->packForget;
	$c->destroy;
	Test::NoWarnings::had_no_warnings ();
	done_testing;
	exit 0;
	}
    } # next_ix

$c->after ($delay, \&next_ix);

MainLoop;
