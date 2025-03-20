package Tk::ListBrowser::LBCanvas;

use warnings;
use strict;
use vars qw ($VERSION);
use Carp;

$VERSION = 0.02;

use base qw(Tk::Derived Tk::Canvas);

Construct Tk::Widget 'LBCanvas';

my $gself; #global self, I know I am cursing here.

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-keycall => ['CALLBACK'],
		DEFAULT => [ $self ],
	);
	$gself = $self;
}

sub ClassInit {
	my ($class,$mw) = @_;
	$class->SUPER::ClassInit($mw);
	for (qw/Escape Return space/) {
		my $bnd = $_;
		$mw->bind($class, "<$bnd>", sub { $gself->KeyPress($bnd) });
	}
	for (qw/Down End Home Left Right Up/) {
		my $bnd = $_;
		$mw->bind($class, "<$bnd>", sub { $gself->KeyPress($bnd) });
		$mw->bind($class, "<Shift-$bnd>", sub { $gself->KeyPress("Shift-$bnd") });
		$mw->bind($class, "<Control-$bnd>", sub { $gself->KeyPress("Control-$bnd") });
		$mw->bind($class, "<Control-Shift-$bnd>", sub { $gself->KeyPress("Control-Shift-$bnd") });
	}
}

sub KeyPress {
	my ($self, $key) = @_;
	$self->Callback('-keycall', $key)
}

1;