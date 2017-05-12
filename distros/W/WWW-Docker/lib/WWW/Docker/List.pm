package WWW::Docker::List;
use Moose;
use namespace::autoclean;

with 'WWW::Docker::Client';

sub containers {
	my $self       = shift;
	my $item_info  = $self->get('//containers/json');
	my @containers = $self->expand('Container', $item_info);
	return wantarray ? @containers : \@containers;
}

sub images {
	my $self       = shift;
	my $item_info  = $self->get('//images/json');
	my @containers = $self->expand('Image', $item_info);
	return wantarray ? @containers : \@containers;
}

__PACKAGE__->meta->make_immutable();

1;
