#!perl -w
use strict;
use Tk;
use Test;

BEGIN { plan tests => 22 }

use Tk::MinMaxScale;

my $vn = 94;
my $vx = 117;
my $wn = -10;
my $wx = 90;
my $un = 40;
my $ux = 50;
my $tn = 20;
my $tx = 110;

my $mw = new MainWindow;

my $mms1 = $mw->MinMaxScale(
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
	-orient => 'vertical',
	-resolution => 1,
	-label => 'min-max',
	-command => \&s2,
	-variablemin => \$wn,
	-variablemax => \$wx,
)->pack;


$mw->after(200, \&start_test);

MainLoop;

sub s1 {
	# does nothing
}

sub s2 {
	# does nothing
}
# from 0 to 100
sub start_test {
	ok($mms1->minvalue == 94);
	ok($vn == 94);
	ok($mms1->maxvalue == 100);
	ok($vx == 100);
	ok($mms2->minvalue == 0);
	ok($wn == 0);
	ok($mms2->maxvalue == 90);
	ok($wx == 90);

	# configure -variablemax
	$mms1->configure(-variablemax => \$ux);
	&updt(undef, 0);
	ok($mms1->minvalue == 50);
	ok($mms1->maxvalue == 50);

	$mms2->configure(-variablemax => \$tx);
	&updt(undef, 0);
	ok($mms2->minvalue == 0);
	ok($mms2->maxvalue == 100);

	# configure -variablemin
	$mms1->configure(-variablemin => \$un);
	&updt(undef, 0);
	ok($mms1->minvalue == 40);
	ok($mms1->maxvalue == 50);

	$mms2->configure(-variablemin => \$tn);
	&updt(undef, 0);
	ok($mms2->minvalue == 20);
	ok($mms2->maxvalue == 100);

	&updt($tn, 60);
	ok($mms2->minvalue == 60);

	&updt($un, 38);
	ok($mms1->minvalue == 38);

	&updt($ux, 53);
	ok($mms1->maxvalue == 53);

	&updt($tx, 53);
	ok($mms2->maxvalue == 53);
	ok($mms2->minvalue == 53);

	&updt($tn, 38);
	ok($mms2->minvalue == 38);

	# that's all folks
	sleep 1;
	exit;
}

sub updt {
	$_[0] = $_[1] if $_[0];
	$mw->update;
	$mw->after(300);
}
