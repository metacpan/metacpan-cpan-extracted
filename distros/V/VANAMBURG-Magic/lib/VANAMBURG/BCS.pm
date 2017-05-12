package VANAMBURG::BCS;
use v5.10;
use Moose;
extends 'VANAMBURG::Packet';
with 'VANAMBURG::SHoCkeDOrder';
use VANAMBURG::StackCard;
use VANAMBURG::FaceValueSingleton;
use VANAMBURG::SuitSingletonSHoCkeD;

=head1 VANAMBURG::BCS

Models Richard Osterlinds Breakthrough Card System for the purpose
of providing a training system and trick simulations.

You can get a number of printed and DVD resources for learning the BCS 
system, as well as shortcuts and routines, at Richard Osterlinds web site: 
http://osterlindmysteries.com/store/ 

This class has all the methods inherited from:
L<VANAMBURG::SHoCkeDOrder>
L<VANAMBURG::Packet>
=cut


=head2 BUILD

Initialize the BCS order in this packet of cards.

=cut 

sub BUILD {
	my $self = shift;

	my $fvs = VANAMBURG::FaceValueSingleton->instance;
	my $sss = VANAMBURG::SuitSingletonSHoCkeD->instance;

	my $first_card = VANAMBURG::StackCard->new(
		value        => $fvs->ace,
		suit        => $sss->spade,
		stack_number => 1
	);
	$self->add_card($first_card);
	my $last_card = $first_card;
	for ( 2 .. 52 ) {
		$last_card = $self->card_after($last_card);
		$self->add_card($last_card);
	}

}

=head2 calc_suit

The suit of the next card is dependent upon the value
of the next card and the suit of the previous card. Given
both of those pieces of information, this method
returns the suit for the next card in the BCS system.

=cut

sub calc_suit {
	my ( $self, $prev_card, $new_value ) = @_;
	given ( $new_value->value ) {
		when ( [ 1, 2, 3 ] ) { return $prev_card->suit; }
		when ( [ 4, 5, 6 ] ) {
			return $self->opposite_suit( $prev_card->suit );
		}
		when ( [ 7, 8, 9 ] ) {
			return $self->previous_suit( $prev_card->suit );
		}
		when ( [ 10, 11, 12, 13 ] ) {
			return $self->next_suit( $prev_card->suit );
		}
	}
}

=head2 card_after

Given a card, and instance of L<VANAMBURG::StackCard>, this method returns the next card in the system.

Returns an instance of L<VANAMBURG::StackCard>

=cut

sub card_after {
	my ( $self, $card ) = @_;

	my $next_val_index =
	  ( ( ( ( $card->value->value * 2 ) % 13 ) + $card->suit->value ) % 13 ) -
	  1;
	my $next_value =
	  VANAMBURG::FaceValueSingleton->instance->default_value_cycle->[$next_val_index];
	my $next_suit = $self->calc_suit( $card, $next_value );
	VANAMBURG::StackCard->new(
		value        => $next_value,
		suit         => $next_suit,
		stack_number => $card->stack_number + 1,
	);
}

1;
