package VANAMBURG::SHoCkeDOrder;
use Moose::Role;
use VANAMBURG::SuitSingletonSHoCkeD;


=head1 VANAMBURG::SHoCkeDPacket

An role provides extension of VANAMBURG::Packet that provides methods for useful for
stacks in SHoCKeD order.

=cut

=head2 suit_cycle

    my $arrayref = $packet->suit_cycle;
    
Returns an array reference of 4 VANAMBURG::OrderedSuit objects
representing the order of suits in a SHoCkeD stack.

This is a short cut to accessing VANAMBURG::SuitSingletonSHoCkeD::suit_cycle.

=cut

has 'suit_cycle' => (
	is      => 'ro',
	lazy    => 1,
	isa     => 'ArrayRef[VANAMBURG::Suit]',
	default => sub {VANAMBURG::SuitSingletonSHoCkeD->instance->suit_cycle}
);

=head2 opposite_suit

Returns the mate of the card passed as input.

    my $heart = $packet->opposite_suit(VANAMBURG::SuitSingletonSHoCkeD->instance->diamond);

This is a shortcut to VANAMBURG::SuitSingletonSHoCkeD::opposite_suit

=cut

sub opposite_suit {
	my ( $self, $suit ) = @_;
	return VANAMBURG::SuitSingletonSHoCkeD->instance->opposite_suit($suit);	
}

=head2 next_suit

Returns the suit following the input suit for a SHoCkeD packet.

    my $heart = $packet->next_suit(VANAMBURG::SuitSingletonSHoCkeD->instance->spade);
    my $spade = $packet->next_suit(VANAMBURG::SuitSingletonSHoCkeD->instance->diamond);
    
This is a short cut to VANAMBURG::SuitSingletonSHoCkeD::next_suit
    
=cut

sub next_suit {
	my ( $self, $suit ) = @_;
	return VANAMBURG::SuitSingletonSHoCkeD->instance->next_suit($suit);
}

=head2 previous_suit

Returns the suit preceding the input suit for a SHoCkeD packet.

    my $heart = $packet->next_suit(VANAMBURG::SuitSingletonSHoCkeD->instance->club);
    my $diamond = $packet->next_suit(VANAMBURG::SuitSingletonSHoCkeD->instance->spade);
    
This is a short cut to VANAMBURG::SuitSingletonSHoCkeD::previous_suit
    
=cut

sub previous_suit {
	my ( $self, $suit ) = @_;
	return VANAMBURG::SuitSingletonSHoCkeD->instance->previous_suit($suit);
}

1;
