#!perl -w
use strict;

use Tk;
use Test;

BEGIN { plan tests => 130 }

use Tk::MinMaxScale;
my $delay = 50;

my $mw = new MainWindow;


my $vn = 94;
my $vx = 117;
my $mms1 = $mw->MinMaxScale(
	-from => 50.0,
	-to => 150.0,
	-orient => 'horizontal',
	-resolution => 0.1,
	-command => \&s1,
	-labelmin => 'mini',
	-labelmax => 'max',
	-label => 'minmax',
	-variablemin => \$vn,
	-variablemax => \$vx,
)->pack;

my $wn = 50;
my $wx = 70;
my $mms2 = $mw->MinMaxScale(
	-from => 30,
	-to => 80,
	-orient => 'vertical',
	-resolution => 1,
	-label => 'min-max',
	-variablemin => \$wn,
	-variablemax => \$wx,
)->pack;

$mw->after(2000, &start_test);

MainLoop;

sub start_test {
	for (1..19) {
		$wn++;
		$mw->update;
		$mw->after($delay);
		ok($wn < $wx);
	}

	$mw->after(1000);

	for (20..29) {
		$wn++;
		$mw->update;
 		ok($wx == $wn);
	}

	$mw->after(1000);

	for (30..31) {
		$wn++;
		$mw->update;
		$mw->after($delay);
		ok($wn == 80);
		ok($wx == 80);
	}

	$mw->after(1000);

	$wn = 40;
	$wx = 60;

	$mw->after(1000);

	for (33..51) {
		$wx--;
		$mw->update;
		$mw->after($delay);
		ok($wx > $wn);
	}

	$mw->after(1000);

	for (52..61) {
		$wx--;
		$mw->update;
 		ok($wn == $wx);
	}

	$mw->after(1000);

	for (62..63) {
		$wx--;
		$mw->update;
		$mw->after($delay);
		ok($wn == 30);
		ok($wx == 30);
	}

	$mw->after(1000);

	$wn = 40;
	$wx = 60;

	$mw->after(1000);

	if ($mw->ismapped) {
		$mw->focusForce;
		$mw->eventGenerate('<Shift_L>');
		
		for (67..96) {
			$wn++;
			$mw->update;
			$mw->after($delay);
			ok(($wx - $wn) == 20);
		}
		ok($wn == 60);
		ok($wx == 80);
	
		$mw->after(1000);
	
		$wn = 40;
		$wx = 60;
	
		$mw->after(1000);
	
		for (99..128) {
			$wx--;
			$mw->update;
			$mw->after($delay);
			ok(($wx - $wn) == 20);
		}
		ok($wn == 30);
		ok($wx == 50);
		
		$mw->after(1000);
	}
	else {
		# just in case of...
		print "main window is not mapped\n";
		for (67..130) { ok(1) };
	}

	# that's all folks
	exit;
}

sub s1 {
	# does nothing
}
