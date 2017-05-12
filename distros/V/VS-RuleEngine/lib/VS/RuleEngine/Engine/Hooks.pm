use strict;
use warnings;

use Carp qw(croak);

use VS::RuleEngine::Engine::Common;
use VS::RuleEngine::TypeDecl;

sub add_hook {
	my ($self, $name, $hook, $defaults, @args) = @_;
    $self->_check_add_args('Hook', \&has_hook, $name, $hook);
	$self->_hooks->set($name => VS::RuleEngine::TypeDecl->new($hook, $defaults, @args));
}

sub hooks {
	my $self = shift;
	return $self->_hooks->keys;
}

sub has_hook {
    my ($self, $name) = @_;
    return $self->_hooks->exists($name);
}

sub _get_hook {
	my ($self, $name) = @_;

	if ($self->has_hook($name)) {
		return $self->_hooks->get($name);
	}
    else {
	    croak "Can't find hook '$name'";
    }
}

sub add_pre_hook {
    my ($self, $name) = @_;
    
    if ($self->has_hook($name)) {
        push @{$self->_pre_hooks}, $name;
    }
    else {
        croak "Can't add hook '$name' because it does not exist";
    }
}

sub add_post_hook {
    my ($self, $name) = @_;
    
    if ($self->has_hook($name)) {
        push @{$self->_post_hooks}, $name;
        return;
    }
    else {
        croak "Can't add hook '$name' because it does not exist";
    }
}

1;
__END__

=head1 DESCRIPTION

Mixin for hooks

=cut
