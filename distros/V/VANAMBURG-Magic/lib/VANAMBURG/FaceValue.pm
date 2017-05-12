package VANAMBURG::FaceValue;
use Moose;

=head2 VANAMBURG::FaceValue

Represents the face value of a card.  See also VANAMBURG::Suit.

=cut

=head2 name

The name of the face value is an full name suchas "Jack", "Ace", etc.

=cut

has 'name' => ( isa => 'Str', is => 'ro', required => 1 );

=head2 value

The value of the card is a number 1 through 13, where Ace is 1,
Two is 2, King is 13, etc.

=cut

has 'value' => ( isa => 'Int', is => 'ro', required => 1 );

=head2 abbreviation

A single character text abbreviation for the face value.  Ace is "A", two is "2",
Jack is "J", etc.

=cut

has 'abbreviation' => ( isa => 'Str', is => 'ro', required => 1 );

=head2 equals

Returns true (1) when the name and value of this object is the same as that
passed to the method, otherwise returns false (0).

=cut

sub equals {
	my ( $self, $other ) = @_;
	return 0 if ( !defined $other );
	if ( $self->name eq $other->name && $self->value == $other->value ) {
		return 1;
	}
	else {
		return 0;
	}
}
1;
