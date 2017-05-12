#!/pro/bin/perl

use strict;
use warnings;

use     Test::More;
require Test::NoWarnings;

BEGIN {
    use_ok ("Tk");
    use_ok ("Tk::Clock");
    }

my ($delay, $m, $c) = ($ENV{TK_TEST_LENGTH} || 5000) * 2;
unless ($m = eval { MainWindow->new  (-title => "clock") }) {
    diag ("No valid Tk environment");
    done_testing;
    exit 0;
    }

ok ($c = $m->Clock (-background => "Black"),	"Clock Widget");
like ($c->config (
    tickColor => "Orange",
    handColor => "Red",
    secsColor => "Green",
    timeColor => "lightBlue",
    dateColor => "Gold",
    timeFont  => "-misc-fixed-medium-r-normal--13-*-75-75-c-*-iso8859-1",
    autoScale => 1,
    ), qr(^Tk::Clock=HASH), "config");
ok ($c->pack (-expand => 1, -fill => "both"), "pack");

print "# Feel free to resize the clock now with your mouse!\n";

$c->after ($delay, sub {
    $c->destroy;
    ok (!Exists ($c), "Destroy Clock");
    $m->destroy;
    ok (!Exists ($m), "Destroy Main");

    Test::NoWarnings::had_no_warnings ();
    done_testing;
    });

MainLoop;
