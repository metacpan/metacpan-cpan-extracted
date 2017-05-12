use strict;
use warnings;

use Carp qw(croak);

use VS::RuleEngine::Engine::Common;
use VS::RuleEngine::TypeDecl;

sub add_rule {
	my ($self, $name, $rule, $defaults, @args) = @_;
    $self->_check_add_args('Rule', \&has_rule, $name, $rule);
	$self->_rules->set($name => VS::RuleEngine::TypeDecl->new($rule, $defaults, @args));
	$self->_rule_actions->set($name => []);
	push @{$self->_rule_order}, $name;
}

sub add_rule_action {
    my ($self, $name, $action) = @_;

    my $actions = $self->_get_rule_actions($name);
    push @$actions, $action;
}

sub rules {
	my $self = shift;
	return $self->_rules->keys;
}

sub has_rule {
    my ($self, $name) = @_;
    return $self->_rules->exists($name);
}

sub _get_rule {
    my ($self, $name) = @_;
    
    if ($self->has_rule($name)) {
        return $self->_rules->get($name);
    }
    
    croak "Rule '${name}' does not exist";
}

sub _get_rule_actions {
    my ($self, $name) = @_;
    
    if ($self->has_rule($name)) {
        return $self->_rule_actions->get($name);
    }
    
    croak "Rule '${name}' does not exist";    
}

sub set_rule_order {
    my ($self, @order) = @_;
    
    $self->{_rule_order} = \@order;
}

sub rule_order {
    my $self = shift;
    return @{$self->_rule_order};
}

1;
__END__

=head1 DESCRIPTION

Mixin for rules

=cut
