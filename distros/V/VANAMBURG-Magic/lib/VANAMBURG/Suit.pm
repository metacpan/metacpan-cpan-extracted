package VANAMBURG::Suit;
use Moose;

=head1 VANAMBURG::Suit

Represents the suit aspect of a card.

=cut

=head2 name

The name of the card, such as "Jack", "Queen", "Two", etc.

=cut

has 'name'         => ( isa => 'Str', is => 'ro', required => 1 );

=head2 abbreviation

A single character representation of the suit such as "H" for heard, etc.

=cut

has 'abbreviation' => ( isa => 'Str', is => 'ro', required => 1 );

=head2 unicode_char

A unicode represendation of the suit symbol.

=cut

has 'unicode_char' => ( isa => 'Str', is => 'ro', required => 1 );

=head2 equals

Returns true (1) if the name and abbreviation of this object are the
same as the suit passed as the parameter.

=cut

sub equals {
    my ( $self, $other ) = @_;
    return 0 if ( !defined $other );
    if ( $self->name eq $other->name && $self->abbreviation eq $other->abbreviation ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;
