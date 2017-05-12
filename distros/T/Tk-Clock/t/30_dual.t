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
unless ($m = eval { MainWindow->new  (-title => "clock", -background => "Black") }) {
    diag ("No valid Tk environment");
    done_testing;
    exit 0;
    }

my %defconfig = (
    -background	=> "Black",

    useDigital	=> 1,
    autoScale	=> 1,
    useAnalog	=> 1,
    useInfo	=> 1,
    ana24hour	=> 0,
    secsColor	=> "Green",
    tickColor	=> "Blue",
    tickFreq	=> 1,
    timeFont	=> "{fixed} 11",
    timeColor	=> "lightBlue",
    timeFormat	=> "HH:MM:SS",
    dateFont	=> "{fixed} 11",
    dateColor	=> "#cfb53b",
    infoFont	=> "{Helvetica} 11 bold",
    );

ok (my $c1 = $m->Clock (%defconfig),			"Clock Local TimeZone");
like ($c1->config ((
    anaScale   => 200,
    infoFormat => "Omega",
    handColor  => "Red",
    timeZone   => $ENV{TZ} || undef,
    dateFormat => "Local",
    )), qr(^Tk::Clock=HASH), "config");
ok ($c1->grid (-column => 0, -row => 0, -sticky => "news"), "grid");

ok (my $c2 = $m->Clock (%defconfig),			"Clock GMT");
like ($c2->config (
    anaScale   => 200,
    infoFormat => "Hc:Mc:Sc",
    infoFont   => "{DejaVu Sans} 10",
    timerValue => 12345,	# 04:25:45
    handColor  => "Orange",
    timeZone   => "GMT",
    dateFormat => "London (GMT)",
    ), qr(^Tk::Clock=HASH), "config");
ok ($c2->grid (-column => 0, -row => 1, -sticky => "news", -padx => 20), "grid");

ok (my $c3 = $m->Clock (%defconfig),			"Clock MET-1METDST");
like ($c3->config (
    anaScale   => 200,
    infoFormat => "HH:MM:SS",
    handColor  => "Yellow",
    timeZone   => "MET-1METDST",
    dateFormat => "Amsterdam (MET)",
    ), qr(^Tk::Clock=HASH), "config");
ok ($c3->grid (-column => 1, -row => 0, -sticky => "news", -pady => 20), "grid");

ok (my $c4 = $m->Clock (%defconfig),			"Clock Tokyo");
like ($c4->config (
    anaScale   => 200,
    countDown  => 1,
    useLocale  => ($^O eq "MSWin32" ? "Japanese_Japan.932" : "ja_JP.utf8"),
    infoFormat => "ddd mmm",
    handColor  => "Yellow",
    timeZone   => "Asia/Tokyo",
    dateFormat => "Asia/Tokyo",
    ), qr(^Tk::Clock=HASH), "config");
ok ($c4->grid (-column => 1, -row => 1, -sticky => "news", -padx => 20, -pady => 20), "grid");

for (0..1) {
    $m->gridColumnconfigure ($_, -weight => 1);
    $m->gridRowconfigure    ($_, -weight => 1);
    }

$delay += 5 * $period;
$c3->after ($delay, sub {
    $_->destroy for $c1, $c2, $c3, $c4;
    ok (!Exists ($_), "Destroy Clock") for $c1, $c2, $c3, $c4;
    $m->destroy;
    ok (!Exists ($m), "Destroy Main");

    Test::NoWarnings::had_no_warnings ();
    done_testing;
    });

MainLoop;
