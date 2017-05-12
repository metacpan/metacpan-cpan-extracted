package VANAMBURG::SiStebbins;
use Moose;
extends 'VANAMBURG::Packet';
use Moose::Util::TypeConstraints;
use VANAMBURG::FaceValueSingleton;
use VANAMBURG::SuitSingletonCHaSeD;
use VANAMBURG::SuitSingletonSHoCkeD;
use VANAMBURG::StackCard;

=head1 VANAMBURG::SiStebbins

A class to represent the classic Si Stebbins stack.  CHaSeD and SHoCkeD 
orders are optional as well as a step of 3 or 4

=cut

subtype 'SuitOrder', as 'Str', where { $_ =~ /(CHaSeD|SHoCkeD)/ };

has 'step'       => ( is => 'ro', isa => 'Int',       default => 3 );
has 'suit_order' => ( is => 'ro', isa => 'SuitOrder', default => 'CHaSeD' );

=head2 BUILD

Post constructor Moose method to setup instance of a Packet
in the orrect Si Stebbins suit order (SHoCkeD or CHaSeD)

=cut

sub BUILD {
	my $self = shift;

	my $fvs        = VANAMBURG::FaceValueSingleton->instance;
	my $first_card = VANAMBURG::StackCard->new(
		value        => $fvs->ace,
		suit         => $self->suit_singleton->suit_cycle->[0],
		stack_number => 1
	);
	$self->add_card($first_card);
	my $last_card = $first_card;
	for ( 2 .. 52 ) {
		$last_card = $self->card_after($last_card);
		$self->add_card($last_card);
	}

}

=head2 suit_singleton

A short cut to the correct SuitSingleton class. 

Returns either VANAMBURG::SuitSingletonCHaSeD->instance() or
VANAMBURG::SuitSingletonSHoCkeD->instance() depending on the 
value of $self->suit_order
	
=cut
 
sub suit_singleton {
	my $self = shift;
	if ( $self->suit_order eq 'CHaSeD' ) {
		return VANAMBURG::SuitSingletonCHaSeD->instance();
	}
	else {
		return VANAMBURG::SuitSingletonSHoCkeD->instance();
	}
}

=head2 card_after

Given a card, and instance of L<VANAMBURG::StackCard>, this method returns the next card in the system.

Returns an instance of L<VANAMBURG::StackCard>

=cut

sub card_after {
	my ( $self, $card ) = @_;

	my $next_val_index = ( ( $card->value->value + $self->step ) % 13 ) - 1;
	my $next_value =
	  VANAMBURG::FaceValueSingleton->instance->default_value_cycle
	  ->[$next_val_index];
	my $next_suit =
	  $self->suit_singleton->next_suit( $card->suit );
	VANAMBURG::StackCard->new(
		value        => $next_value,
		suit         => $next_suit,
		stack_number => $card->stack_number + 1,
	);
}

1;
