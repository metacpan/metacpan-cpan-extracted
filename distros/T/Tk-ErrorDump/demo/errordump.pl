#! /usr/bin/perl

use Tk;
use Tk::ErrorDump;
use Tk::Photo;

my $mw = MainWindow->new();

my $icon = $mw->Photo(-file => "execute.gif");
$mw->Icon(-image => $icon);

my $errdlg = $mw->ErrorDump(
	-icon => $icon, 
	-dumpcode => \&dumper, 
	-filtercode => \&errfilter,
	-defaultfile => '*.tkd');

my $l_dummy = $mw->Label(-text => 'this is a simple example')->pack();
my $btn = $mw->Button(-text => 'Blow up', -command => \&do_stupid)->pack();

Tk::MainLoop();


sub dumper {
	my ($fh, $error, @msgs) = @_;
	
	print $fh "\n**** We got to our dumper with the
	following arguments:\n", $error, "\n", join("\n", @msgs), "\n"
		if $fh;
}

sub errfilter {
	my ($error, @msgs) = @_;
	my @out = ();
	print "in errfilter\n";
	push @out, uc $error;
	foreach my $msg (@msgs) {
		push @out, uc $msg;
	}
	return @out;
}

sub do_stupid {
	$l_dummy->configure(-garbage => 'something');
}