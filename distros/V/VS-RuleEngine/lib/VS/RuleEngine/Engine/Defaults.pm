use strict;
use warnings;

use Carp qw(croak);

sub add_defaults {
	my ($self, $name, $defaults) = @_;
	croak "Defaults '${name}' is already defined" if $self->has_defaults($name);
	
	if (ref $defaults ne 'HASH') {
	    croak "Expected hash reference but got '", ref $defaults, "'";
	}
	
	$self->_defaults->set($name => $defaults);
}

sub defaults {
	my $self = shift;
	return $self->_defaults->keys;
}

sub has_defaults {
    my ($self, $name) = @_;
    return $self->_defaults->exists($name);
}

sub get_defaults {
	my ($self, $name) = @_;

	if ($self->has_defaults($name)) {
		return $self->_defaults->get($name);
	}

	croak "Can't find defaults '$name'";
}

1;
__END__

=head1 DESCRIPTION

Mixin for defaults

=cut
