package VANAMBURG::Card;

=head1 VANAMBURG::Card

Represents a playing card, having a suit and a face value.

=cut

use Moose;

=head2 suit

Returns the instance of VANAMBURG::Suit that represents the suit
of this card.

=cut

has 'suit' => ( isa => 'VANAMBURG::Suit', is => 'ro', required => '1' );

=head2 value

Returns an instance of VANAMBURG::FaceValue that represents the face
value of this card.

=cut

has 'value' =>
  ( isa => 'VANAMBURG::FaceValue', is => 'ro', required => '1' );

=head2 abbreviation

Returns a string abbreviation for this card that is composed of the 
abbrevation of the value and suit of the card.  For example, it 
returns 'AS' for the Ace of Spades, and 'JS' for the Jack of Spades.

=cut

has 'abbreviation' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->value->abbreviation . $self->suit->abbreviation;
    }
);


=head2 unicode_abbreviation

Returns an abbreviation for the card where the suit is
the unicode character for the suit of the card.

=cut

has 'unicode_abbreviation' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->value->abbreviation . $self->suit->unicode_char;
    }
);

=head2 equals

Returns "true" (1) if the value and suit of the input card matches
that of this card.

=cut

sub equals {
    my ( $self, $other ) = @_;
    return 0 if ( !defined $other );
    if (   $self->suit->equals( $other->suit )
        && $self->value->equals( $other->value ) )
    {
        return 1;
    }
    else {
        return 0;
    }

}

=head2 display_name

Returns an english name for this card, such as 'Ace of Spades'.

=cut

sub display_name {
    my $self = shift;
    return $self->value->name . " of " . $self->suit->name;
}

1;