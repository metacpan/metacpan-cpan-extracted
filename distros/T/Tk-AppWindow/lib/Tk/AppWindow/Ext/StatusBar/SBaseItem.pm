package Tk::AppWindow::Ext::StatusBar::SBaseItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Frame);
Construct Tk::Widget 'SBaseItem';

sub Populate {
	my ($self,$args) = @_;

	my $label = delete $args->{'-label'};
	my $itempack = delete $args->{'-itempack'};
	unless (defined $itempack) {
		$itempack = [-side=> 'left', -padx => 2, -pady => 2];
	}
	$self->{ITEMPACK} = $itempack;

	$self->SUPER::Populate($args);

	if (defined $label) {
		$self->Label(-text => "$label:")->pack($self->ItemPack);
	}
	$self->ConfigSpecs(
		-updatecommand => ['CALLBACK'],
		DEFAULT => ['SELF'],
	);
}

sub ItemPack {
	my $i = $_[0]->{ITEMPACK};
	return @$i
}

sub Remove {
	$_[0]->packForget
}

sub Update {
}

1;
