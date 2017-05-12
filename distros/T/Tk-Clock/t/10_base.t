#!/pro/bin/perl

use strict;
use warnings;

use     Test::More;
require Test::NoWarnings;

BEGIN {
    use_ok ("Tk");
    use_ok ("Tk::Clock");
    }

my ($delay, $period, $m, $c) = (0, $ENV{TK_TEST_LENGTH} || 5000);
unless ($m = eval { MainWindow->new  (-title => "clock") }) {
    diag ("No valid Tk environment");
    done_testing;
    exit 0;
    }

ok ($c = $m->Clock (-background => "Black"),	"Clock Widget");

# Safe to use en_US.UTF-8, as the fallback is C and all values are the same
foreach my $loc ("C", "en_US.UTF-8") {
    is (Tk::Clock::_month ($loc, 0, 0), "1",       "Month   format m    Jan in $loc");
    is (Tk::Clock::_month ($loc, 2, 1), "03",      "Month   format mm   Mar in $loc");
    is (Tk::Clock::_month ($loc, 4, 2), "May",     "Month   format mmm  May in $loc");
    is (Tk::Clock::_month ($loc, 6, 3), "July",    "Month   format mmmm Jul in $loc");

    is (Tk::Clock::_wday  ($loc, 0, 0), "Sun",     "Weekday format ddd  Sun in $loc");
    is (Tk::Clock::_wday  ($loc, 2, 1), "Tuesday", "Weekday format dddd Tue in $loc");
    }

like ($c->config (
    tickColor => "Orange",
    handColor => "Red",
    secsColor => "Green",
    timeColor => "lightBlue",
    dateColor => "Gold",
    timeFont  => "Helvetica 6",
    dateFont  => "Helvetica 6",
    ), qr(^Tk::Clock=HASH), "config");
ok ($c->pack (-expand => 1, -fill => "both"), "pack");
# Three stupid tests to align the rest
is ($delay, 0, "Delay is 0");
like ($period, qr/^\d+$/, "Period is $period");

$delay += $period;
like ($delay, qr/^\d+$/, "First after $delay");

$c->after ($delay, sub {
    $c->configure (-background => "Blue4");
    ok ($c->config (
	tickColor  => "Yellow",
	useAnalog  => 1,
	useInfo    => 0,
	useDigital => 0,
	), "Blue4   Ad Yellow");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Tan4");
    ok ($c->config (
	useAnalog  => 0,
	useInfo    => 0,
	useDigital => 1,
	), "Tan4    aD");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Maroon4");
    ok ($c->config (
	useAnalog  => 1,
	useInfo    => 1,
	useDigital => 4,	# Should be normalized to 1
	dateFormat => "m/d/y",
	timeFormat => "hh:MM A",
	_digSize   => 800,	# Should be ignored
	), "Maroon4 AD m/d/y hh:MM A");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Red4");
    ok ($c->config (
	useAnalog  => 0,
	useInfo    => 0,
	useDigital => 1,
	dateFormat => "mmm yyy",
	timeFormat => "HH:MM:SS",
	), "Red4    aD mmm yyy HH:MM:SS");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Gray10");
    ok ($c->config (
	useAnalog  => 1,
	useInfo    => 1,
	useDigital => 1,
	digiAlign  => "right",
	), "Gray10  right digital");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Gray30");
    ok ($c->config (
	useAnalog  => 1,
	useInfo    => 0,
	useDigital => 1,
	digiAlign  => "left",
	), "Gray30  left digital");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Purple4");
    ok ($c->config (
	useAnalog  => 0,
	useInfo    => 0,
	useDigital => 1,
	useLocale  => ($^O eq "MSWin32" ? "Japanese_Japan.932" : "ja_JP.utf8"),
	timeFont   => "Helvetica 8",
	dateFont   => "Helvetica 8",
	dateFormat => "dddd\nd mmm yyy",
	timeFormat => "",
	), "Purple4 aD dddd\\nd mmm yyy ''");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Gray75");
    ok ($c->config (
	useAnalog  => 1,
	useInfo    => 1,
	useDigital => 0,
	anaScale   => 300,
	timeFont   => "Helvetica 12",
	dateFont   => "Helvetica 12",
	infoFormat => "Tk-Clock",
	), "Gray75  Ad scale 300");
    });

$delay += $period;
$c->after ($delay, sub {
    ok ($c->config (
	useAnalog  => 1,
	useInfo    => 0,
	useDigital => 0,
	anaScale   => 67,
	tickFreq   => 5,
	), "        Ad scale  67 tickFreq 5");
    });

$delay += $period;
$c->after ($delay, sub {
    ok ($c->config (
	useAnalog  => 1,
	useInfo    => 0,
	useDigital => 1,
	anaScale   => 100,
	tickFreq   => 5,
	dateFormat => "ww dd-mm",
	timeFormat => "dd HH:SS",
	), "        AD scale 100 tickFreq 5 ww dd-mm dd HH:SS");
    });

$delay += $period;
$c->after ($delay, sub {
    ok ($c->config ({
	anaScale   => 150,
	dateFont   => "Helvetica 9",
	}), "        Increase date font size");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Black");
    ok ($c->config ({
	anaScale   => 250,
	useAnalog  => 1,
	useInfo    => 0,
	useDigital => 0,
	secsColor  => "Red",
	tickColor  => "White",
	handColor  => "White",
	handCenter => 1,
	tickFreq   => 1,
	tickDiff   => 1,
	}), "        Station clock: hand centers and tick width");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->configure (-background => "Black");
    ok ($c->config ({
	useInfo     => 1,
	useDigital  => 1,
	anaScale    => 300,
	dateFormat  => "dd-mm-yyyy",
	timeFormat  => "HH:MM:SS",
	localOffset => -363967, # minus 4 days, 5 hours, 6 minutes and 7 seconds
	}), "        Station clock: Time offset -4'05:06:07");
    });

$delay += $period;
$c->after ($delay, sub {
    $c->destroy;
    ok (!Exists ($c), "Destroy Clock");
    $m->destroy;
    ok (!Exists ($m), "Destroy Main");

    Test::NoWarnings::had_no_warnings ();
    done_testing;
    });

MainLoop;
