package VANAMBURG::OrderedSuit;
use Moose;
extends 'VANAMBURG::Suit';
=head1 VANAMBURG::OrderedSuit

An extension of VANAMBURG::Suit that adds a value attribute
indicating the order of the suit.

=cut

=head2 value

The value indicating the order of the suit, useful for such
stacks as CHaSeD or SHoCkeD.

=cut

has 'value' => ( is => 'ro', isa => 'Int', required => 1 );

=head2 equals

Returns true (1) if the name, abbreviation and value of this object
is the same as that passed as a parameter.

=cut

override 'equals' => sub {
	my ( $self, $other ) = @_;
	return 0 if ( !defined $other );
	if (   $self->name eq $other->name
		&& $self->abbreviation eq $other->abbreviation
		&& $self->value == $other->value )
	{
		return 1;
	}
	else {
		return 0;
	}
};

1;
