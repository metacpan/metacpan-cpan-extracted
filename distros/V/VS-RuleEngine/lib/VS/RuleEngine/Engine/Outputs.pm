use strict;
use warnings;

use Carp qw(croak);

use VS::RuleEngine::Engine::Common;
use VS::RuleEngine::TypeDecl;

sub add_output {
	my ($self, $name, $output, $defaults, @args) = @_;
    $self->_check_add_args('Output', \&has_output, $name, $output);
	$self->_outputs->set($name => VS::RuleEngine::TypeDecl->new($output, $defaults, @args));
}

sub outputs {
	my $self = shift;
	return $self->_outputs->keys;
}

sub has_output {
    my ($self, $name) = @_;
    return $self->_outputs->exists($name);
}

sub _get_output {
	my ($self, $name) = @_;

	if ($self->has_output($name)) {
		return $self->_outputs->get($name);
	}

	croak "Can't find output '$name'";
}

1;
__END__

=head1 DESCRIPTION

Mixin for outputs

=cut
