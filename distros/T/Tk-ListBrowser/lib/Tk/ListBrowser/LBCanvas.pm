package Tk::ListBrowser::LBCanvas;

use warnings;
use strict;
use vars qw ($VERSION);
use Carp;

$VERSION = 0.04;

use base qw(Tk::Derived Tk::Canvas);

Construct Tk::Widget 'LBCanvas';

sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-keycall => ['CALLBACK'],
		DEFAULT => [ $self ],
	);
}

sub ClassInit {
	my ($class,$mw) = @_;
	$class->SUPER::ClassInit($mw);
	for (qw/Escape Return space Down Left Right Up End Home/) {
		my $bnd = $_;
		$mw->bind($class, "<$bnd>", ['KeyPress', $bnd]);
	}
	for (qw/Down Left Right Up End Home/) {
		my $bnd = $_;
		$mw->bind($class, "<Shift-$bnd>", ['KeyPress', "Shift-$bnd"]);
	}
	for (qw/End Home/) {
		my $bnd = $_;
		$mw->bind($class, "<Shift-$bnd>", ['KeyPress', "Shift-$bnd"]);
		$mw->bind($class, "<Control-$bnd>", ['KeyPress', "Control-$bnd"]);
		$mw->bind($class, "<Control-Shift-$bnd>", ['KeyPress', "Control-Shift-$bnd"]);
	}
}

sub KeyPress {
	my ($self, $key) = @_;
	$self->Callback('-keycall', $key)
}

1;