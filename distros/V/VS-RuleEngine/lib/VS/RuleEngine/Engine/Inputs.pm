use strict;
use warnings;

use Carp qw(croak);

use VS::RuleEngine::Engine::Common;
use VS::RuleEngine::InputHandler;
use VS::RuleEngine::TypeDecl;

sub add_input {
	my ($self, $name, $input, $defaults, @args) = @_;
	$self->_check_add_args('Input', \&has_input, $name, $input);
	$self->_inputs->set($name => VS::RuleEngine::TypeDecl->new($input, $defaults, @args));
}

sub inputs {
	my $self = shift;
	return $self->_inputs->keys;
}

sub has_input {
    my ($self, $name) = @_;
    return $self->_inputs->exists($name);
}

sub _get_input {
	my ($self, $name) = @_;

	if ($self->has_input($name)) {
		return $self->_inputs->get($name);
	}

	croak "Can't find input '$name'";
}

sub _input_handler {
    my $self = shift;
    my %inputs = map { 
        my $input = $self->_get_input($_);
        $_ => $input->instantiate($self);
     } $self->inputs;
    my $handler = VS::RuleEngine::InputHandler->new(%inputs);
    return $handler;
}


1;
__END__

=head1 DESCRIPTION

Mixin for hooks

=cut
