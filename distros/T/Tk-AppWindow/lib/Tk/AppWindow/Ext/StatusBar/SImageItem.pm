package Tk::AppWindow::Ext::StatusBar::SImageItem;

use Tk;
use base qw( Tk::AppWindow::Ext::StatusBar::STextItem);
Construct Tk::Widget 'SImageItem';
require Tk::Compound;

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		-valueimages => ['PASSIVE', undef, undef, {}],
# 		DEFAULT => ['SELF'],
	);
}

sub Update {
	my $self = shift;
	my $value = $self->Callback(-updatecommand => $self);
	$imagehash = $self->cget('-valueimages');
	my $image = $imagehash->{$value};
	$image = 'error' unless defined $image;
	unless (ref $image) {
		$self->configure(-bitmap => $image);
	} else {
		$self->configure(-image => $image);
	}
}

1;
