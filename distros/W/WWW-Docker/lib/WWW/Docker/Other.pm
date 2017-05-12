package WWW::Docker::Other;
use Moose;
use namespace::autoclean;

with 'WWW::Docker::Client';

sub version {
	my $self = shift;
	return $self->get('//version');
}

sub _forwardable {
	return qw/version/;
}

__PACKAGE__->meta->make_immutable();

1;
