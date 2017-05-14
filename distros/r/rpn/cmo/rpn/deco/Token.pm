package cmo::rpn::deco::Token;

use Moose;
require cmo::rpn::deco::MyStack;

has 'opSymbol' => ( is => 'rw' );

has 'stack' => (
	is  => 'rw',
	isa => 'cmo::rpn::deco::MyStack',
	default   => sub { new cmo::rpn::deco::MyStack() },
);

sub getAnswer {
	my ($self) = shift;
	return $self->stack->peek();
}

sub push {
	my ( $self, $op ) = @_;
	$self->stack->push($op);
}

sub pop {
	my ($self) = shift;
	if ( $self->size() <= 0 ) {
		die Exception->new("Operand is empty");
	}
	return $self->stack->pop();
}

sub size {
	my ($self) = shift;
	return $self->stack->count();
}

sub toString {
	my ($self) = shift;
	return $self->stack->toString();
}

sub clear {
	my ($self) = shift;
	$self->stack->clear();
}

return 1;
