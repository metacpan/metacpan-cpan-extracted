package Tk::AppWindow::Ext::StatusBar::STextItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::AppWindow::Ext::StatusBar::SBaseItem);
Construct Tk::Widget 'STextItem';

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	my $t = $self->Label->pack($self->ItemPack);
	$self->Advertise('value', $t);
	$self->ConfigSpecs(
		-borderwidth => ['SELF'],
		-relief => ['SELF'],
		DEFAULT => [$t],
	);
	$self->Delegates(
		'DEFAULT' => $t,
	);
}

sub Update {
	my $self = shift;
	$self->configure(-text => $self->Callback(-updatecommand => $self));
}

1;
