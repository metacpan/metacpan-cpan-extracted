use strict;
use vars '$loaded';
BEGIN { $^W= 1; $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use Tk;
use Tk::DynaTabFrame;
use Tk::Text;

my %frames = ();
my %texts = ();

my $mw = MainWindow->new();
$mw->geometry('400x400');
$mw->update;

my $dtf = $mw->DynaTabFrame(
	-font => 'Courier 8', 
	-raisecmd => \&raise_cb,
	-tabclose => 1,
	-tabcolor => 'orange',
	-raisecolor => 'green',
	)
	->pack (-side => 'top', -expand => 1, -fill => 'both');
#
#	add a text tab
$texts{"Tab$_"} = $dtf->add(
	"Tab$_",
	-label => "Tab No. $_",
)->Text(
	-width => 50, 
	-height => 30, 
	-wrap => 'none',
	-font => 'Courier 10')
	->pack(-fill => 'both', -expand => 1),
$texts{"Tab$_"}->insert('end', "This is the textual tabframe $_")
	foreach (1..14);

my $tabno = 1;
my $pass = 0;

$mw->after(500, \&test_raise);

Tk::MainLoop();

sub raise_cb { print shift, "\n"; }

sub test_raise {
	$dtf->raise("Tab$tabno");
	$tabno++;
	$mw->after(500, \&test_done)
		if (($tabno == 14) && $pass);
	$dtf->configure(-tabrotate => undef),
	$tabno = 0, $pass++,
		if (($tabno == 15) && (! $pass));
	$mw->after(500, \&test_raise);
}

sub test_done {
	$loaded = 1;
	print "ok 1\n";
	exit;
}
