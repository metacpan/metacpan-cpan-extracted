use strict;
use vars '$loaded';
BEGIN { $^W= 1; $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use Tk;
use Tk::DynaTabFrame;

my @alphas = split //, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

my $mw = MainWindow->new(-width => 200);
$mw->geometry('200x200');
$mw->update;

my $dtf = $mw->DynaTabFrame(
	-font => 'System 8', 
	-tabclose => 1,
	-tabcolor => 'orange',
	-raisecolor => 'green',
	)
	->pack (-side => 'top', -expand => 1, -fill => 'both');
#
#	add many tabs
$dtf->add(
	-caption => $_,
	-label => $_,
)->Text(-width => 60, -height => 10)
	->pack(-fill => 'both', -expand => 1)
	foreach (@alphas);

$mw->after(1000, \&test_done);

Tk::MainLoop();

sub test_done {
	$loaded = 1;
	print "ok 1\n";
	exit;
}
