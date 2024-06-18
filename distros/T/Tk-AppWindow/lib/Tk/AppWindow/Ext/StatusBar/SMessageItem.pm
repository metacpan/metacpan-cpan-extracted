package Tk::AppWindow::Ext::StatusBar::SMessageItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::AppWindow::Ext::StatusBar::SBaseItem);
Construct Tk::Widget 'SMessageItem';

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	my $e = $self->Label(
		-text => ' ',
		-anchor => 'w',
	)->pack(-side => 'left', -expand => 1, -fill => 'x');
	$self->{L} = $e;
	$self->{COLORBCK} = $e->cget('-foreground');
	$self->toplevel->bind('<Any-KeyPress>', sub { $self->Clear });
	$self->toplevel->bind('<Button-1>', sub { $self->Clear });
	$self->ConfigSpecs(
		-borderwidth => ['SELF'],
		-relief => ['SELF'],
		DEFAULT => [$e],
	);
	$self->Delegates(
		'DEFAULT' => $e,
	);
}

sub Clear {
	$_[0]->configure(
		-text => '',
		-foreground => $_[0]->{COLORBCK},
	);
}

sub Message {
	my ($self, $message, $color) = @_;
	$color = $self->{COLORBCK} unless defined $color;

	#shorten message if it is larger than the label allows.
	my $l = $self->{L};
	my $lw = $l->width;
	my $font = $l->cget('-font');
	my $width = $self->fontMeasure($font, $message);
	while ($width > $lw) {
		$message = substr($message, 0, length($message) - 1);
		$width = $self->fontMeasure($font, $message);
	}

	$self->configure(
		-text => $message,
		-foreground => $color,
	);
}

sub Remove {
	my $self = shift;
	$self->toplevel->bindRelease('<Any-KeyPress>');
	$self->toplevel->bindRelease('<Button-1>');
	$self->SUPER::Remove;
}

sub Update {}

1;

