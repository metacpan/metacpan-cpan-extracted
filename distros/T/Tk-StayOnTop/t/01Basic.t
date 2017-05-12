use strict;
use warnings;

use Test;

BEGIN { plan tests => 5 };

use Tk::StayOnTop;
use Tk;

my $status = "Starting";
ok(1); # If we made it this far, we're ok.

my $mw = MainWindow->new();
$mw->Label(-textvariable => \$status)->pack();
ok(2);

$mw->after( 500, sub {
	$status = "Staying on Top!";
	$mw->stayOnTop();
	ok(3);
});

$mw->after( 2500, sub {
	$status = "Back to Normal";
	$mw->dontStayOnTop();
	ok(4);
});

$mw->after( 4500, sub {
	$status = "Done";
	ok(5);
	exit 0;
});

Tk::MainLoop;
