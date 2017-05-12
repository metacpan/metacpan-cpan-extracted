#!perl -w
use strict;
use Tk;
use Test;

BEGIN { plan tests => 8 }

use Tk::MinMaxScale;

my $vn = 94;
my $vx = 117;
my $wn = 65;
my $wx = 86;

my $mw = new MainWindow;

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

my $mms2 = $mw->MinMaxScale(
	-from => 30,
	-to => 120,
	-orient => 'vertical',
	-resolution => 1,
	-label => 'min-max',
	-command => \&s2,
	-variablemin => \$wn,
	-variablemax => \$wx,
)->pack;

$mw->after(1000, \&start_test);

MainLoop;

sub s1 {
	# does nothing
}

sub s2 {
	# does nothing
}

sub start_test {
	# configure/cget -from
	ok($mms1->cget('-from'), 50);
	$mms1->configure(-from => 49);
	ok($mms1->cget('-from'), 49);
	&updt;

	ok($mms2->cget('-from'), 30);
	$mms2->configure(-from => 29);
	ok($mms2->cget('-from'), 29);
	&updt;

	# configure/cget -to
	ok($mms1->cget('-to'), 150);
	$mms1->configure(-to => 100);
	ok($vx == 100);
	&updt;

	ok($mms2->cget('-to'), 120);
	$mms2->configure(-to => 100);
	ok($mms2->cget('-to'), 100);
	&updt;

	# that's all folks
	sleep 1;
	exit;
}

sub updt {
	$mw->update;
	$mw->after(300);
}
