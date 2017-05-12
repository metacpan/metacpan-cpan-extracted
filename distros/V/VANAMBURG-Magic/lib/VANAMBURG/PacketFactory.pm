package VANAMBURG::PacketFactory;

=head1 VANAMBURG::PacketFactory

Provide class methods to create a variety of well know stacks, as well as methods
to create arbitrary packets and stacks from a comma separated list of card abbreviations.

=cut

use VANAMBURG::SuitSingleton;
use VANAMBURG::FaceValueSingleton;
use VANAMBURG::Card;
use VANAMBURG::StackCard;
use VANAMBURG::Packet;
use VANAMBURG::BCS;
use VANAMBURG::SiStebbins;


=head2 create_packet

Given a comma separated list of card abbreviations (e.g., "AD,2S,JD") this method instantiates
a L<VANAMBURG::Packet> with those cards.  The cards are instance of L<VANAMBURG::Card>.

=cut

sub create_packet {
	my ( $class, $csv_cards ) = @_;
	my @abbrevs = split /,/, $csv_cards;
	my $packet = VANAMBURG::Packet->new;
	for my $abbrev (@abbrevs) {
		$abbrev =~ /(\S*)(\S)/;
		my ( $face_val, $suit ) = ( $1, $2 );
		my $card = VANAMBURG::Card->new(
			suit  => VANAMBURG::SuitSingleton->suit_by_abbreviation($suit),
			value => VANAMBURG::FaceValueSingleton->facevalue_by_abbreviation(
				$face_val)
		);
		$packet->add_card($card);
	}
	return $packet;

}

=head2 create_stack

Given a comma separated list of card abbreviations (e.g., "AD,2S,JD") this method instantiates
a L<VANAMBURG::Packet> with those cards.  Similar to create_packet, but the cards are instances
of L<VANAMBURG::StackCard> having a stack number attribute.

=cut

sub create_stack {
	my ( $class, $csv_cards ) = @_;
	my @abbrevs   = split /,/, $csv_cards;
	my $packet    = VANAMBURG::Packet->new;
	my $stack_num = 1;
	for my $abbrev (@abbrevs) {
		$abbrev =~ /(\S*)(\S)/;
		my ( $face_val, $suit ) = ( $1, $2 );
		my $card = VANAMBURG::StackCard->new(
			suit  => VANAMBURG::SuitSingleton->suit_by_abbreviation($suit),
			value => VANAMBURG::FaceValueSingleton->facevalue_by_abbreviation(
				$face_val),
			stack_number => $stack_num++
		);
		$packet->add_card($card);
	}
	return $packet;
}

=head2 create_stack_aronson

Creates an Aronson stack as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_stack_aronson {
	my $class = shift;
	return VANAMBURG::PacketFactory->create_stack(
"JS,KC,5C,2H,9S,AS,3H,6C,8D,AC,10S,5H,2D,KD,7D,8C,3S,AD,7S,5S,QD,AH,8S,3D,7H,QH,5D,7C,4H,KH,4D,10D,JC,JH,10C,JD,4S,10H,6H,3C,2S,9H,KS,6S,4C,8H,9C,QS,6D,QC,2C,9D"
	);
}

=head2 create_stack_joyal_chased

Creates a Martin Joyal stack using the CHaSeD order as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_stack_joyal_chased {
	my $class = shift;
	return VANAMBURG::PacketFactory->create_stack(
"JH,6C,6H,4C,10D,AD,7C,4H,9C,5D,QH,AS,KC,7H,10S,4S,JS,9H,KD,5S,7S,2C,QC,AH,10H,6S,9S,7D,QD,5H,KH,4D,3C,3H,10C,9D,QS,3S,3D,2H,8C,2S,JC,2D,8H,8S,KS,AC,JD,5C,8D,6D"
	);
}

=head2 create_stack_joyal_shocked

Creates a Martin Joyal stack using the SHoCkeD order as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_stack_joyal_shocked {
	my $class = shift;
	return VANAMBURG::PacketFactory->create_stack(
"JH,6S,6H,4S,10D,AD,7S,4H,9S,5D,QH,AH,KC,7H,10C,4C,JS,9H,KD,5C,7C,2S,QC,AH,10C,6C,9C,7D,QD,10H,KH,4D,3S,3H,10D,9D,QS,3C,3D,2H,8S,2C,QC,2D,8H,8C,KS,AS,JD,5S,8D,6D"
	);
}


=head2 create_stack_mnemonica

Creates Juan Tamariz's Mnemonica stack as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_stack_mnemonica {
	my $class = shift;
	return VANAMBURG::PacketFactory->create_stack(
"4C,2H,7D,3C,4H,6D,AS,5H,9S,2S,QH,3D,QC,8H,6S,5S,9H,KC,2D,JH,3S,8S,6H,10C,5D,KD,2C,3H,8D,5C,KS,JD,8C,10S,KH,JC,7S,10H,AD,4S,7H,4D,AC,9C,JS,QD,7C,QS,10D,6C,AH,9D"
	);
}


=head2 create_stack_breakthrough_card_system

Creates Richard Osterlind's Breakthrough Card System stack as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_stack_breakthrough_card_system {
	return VANAMBURG::BCS->new;
}


=head2 create_si_stebbins_shocked_3step

Creates Si Stebbins stack in SHoCkeD order where card values increment by 3 as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_si_stebbins_shocked_3step {
	return VANAMBURG::SiStebbins->new( suit_order => 'SHoCkeD' );
}


=head2 create_si_stebbins_shocked_4step

Creates Si Stebbins stack in SHoCkeD order where card values increment by 4 as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_si_stebbins_shocked_4step {
	return VANAMBURG::SiStebbins->new( suit_order => 'SHoCkeD', step => 4 );
}


=head2 create_si_stebbins_chased_3step

Creates Si Stebbins stack in CHaSeD order where card values increment by 3 as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_si_stebbins_chased_3step {
	return VANAMBURG::SiStebbins->new();
}

=head2 create_si_stebbins_chased_4step

Creates Si Stebbins stack in CHaSeD order where card values increment by 4 as an instance of L<VANAMBURG::Packet>.
Each card is an instance of L<VANAMBURG::StackCard>.

=cut

sub create_si_stebbins_chased_4step {
	return VANAMBURG::SiStebbins->new( step => 4 );
}

1;
