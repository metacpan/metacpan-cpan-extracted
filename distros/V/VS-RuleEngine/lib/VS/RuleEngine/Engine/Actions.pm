use strict;
use warnings;

use Carp qw(croak);

use VS::RuleEngine::Engine::Common;
use VS::RuleEngine::TypeDecl;

sub add_action {
	my ($self, $name, $action, $defaults, @args) = @_;
	$self->_check_add_args('Action', \&has_action, $name, $action);
	$self->_actions->set($name => VS::RuleEngine::TypeDecl->new($action, $defaults, @args));
}

sub actions {
	my $self = shift;
	return $self->_actions->keys;
}

sub has_action {
    my ($self, $name) = @_;
    return $self->_actions->exists($name);
}

sub _get_action {
	my ($self, $name) = @_;

	if ($self->has_action($name)) {
		return $self->_actions->get($name);
	}

	croak "Can't find action '$name'";
}

1;
__END__

=head1 DESCRIPTION

Mixin for actions

=cut
