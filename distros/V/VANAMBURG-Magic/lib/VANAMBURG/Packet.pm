package VANAMBURG::Packet;
use Moose;
use List::Util qw(shuffle);
use List::MoreUtils qw(each_array);
use VANAMBURG::Card;
use VANAMBURG::FaceValueSingleton;

=head1 VANAMBURG::Packet

This class gives models packets or decks of cards.  Methods include a variety
of shuffles and cuts as well as dealing cards from one packet into another.

This is the base class for all the specialized decks in this package, such as 
BCS, Si Stebbins, etc.

=cut

=head2 cards

An array reference containing instances of VANAMBURG::Card objects.

It exposes a number of perl array functions to the main class. Developers 
will want to know about this:

	handles => {
		add_card   => 'push',
		map_cards  => 'map',
		get_card   => 'get',
		card_count => 'count'

=cut

has 'cards' => (
	isa     => 'ArrayRef[VANAMBURG::Card]',
	is      => 'rw',
	default => sub { [] },
	traits  => ['Array'],
	handles => {
		add_card   => 'push',
		map_cards  => 'map',
		get_card   => 'get',
		card_count => 'count'
	}
);

=head2 shuffle_faro_in

Calling this reorders the packed/deck doing an "in faro".  Consult your magical texts for 
more information.

=cut

sub shuffle_faro_in {
	my $self = shift;
	die "can only faro packets with even number of cards"
	  unless $self->card_count % 2 == 0;
	my $half        = $self->card_count / 2;
	my @top_half    = splice @{ $self->cards }, 0, $half;
	my @bottom_half = splice @{ $self->cards }, 0, $half;
	my $new_packet  = VANAMBURG::Packet->new;
	my $ea          = each_array( @bottom_half, @top_half );
	while ( my ( $c1, $c2 ) = $ea->() ) {
		$new_packet->add_card($c1);
		$new_packet->add_card($c2);
	}
	$self->cards( $new_packet->cards );
}

=head2 shuffle_faro_out

Calling this reorders the packed/deck doing an "out faro".  Consult your magical texts for 
more information.

=cut

sub shuffle_faro_out {
	my $self = shift;

	die "can only faro packets with even number of cards"
	  unless $self->card_count % 2 == 0;
	my $half        = $self->card_count / 2;
	my @top_half    = splice @{ $self->cards }, 0, $half;
	my @bottom_half = splice @{ $self->cards }, 0, $half;
	my $new_packet  = VANAMBURG::Packet->new;
	my $ea          = each_array( @top_half, @bottom_half );
	while ( my ( $c1, $c2 ) = $ea->() ) {
		$new_packet->add_card($c1);
		$new_packet->add_card($c2);
	}
	$self->cards( $new_packet->cards );
}

=head2 shuffle_random

Randomizes the order of the deck much more than an ordinary shuffle would, for better or worse.

=cut

sub shuffle_random {
	my $self      = shift;
	my @new_cards = shuffle @{ $self->cards };
	$self->cards( \@new_cards );
}

=head2 deal

	my $new_packet = $self->deal(10);
	
Removes n number of cards from the top of this packet, reversing their order, as in an ordinary deal.
The resulting packet, and instance of VANAMBURG::Packet, is returned.

=cut

sub deal {
	my ( $self, $how_many ) = @_;

	my $new_packet = VANAMBURG::Packet->new;
	my @dealt = splice @{ $self->cards }, 0, $how_many;
	while (@dealt) {
		$new_packet->add_card( pop @dealt );
	}
	return $new_packet;
}

=head2 insert_packet

	# Insert a packet after 5 cards from the top of this packet.
	$self->insert_packet(5, $other_packet);

Inserts a packet into this packet after a specified number of cards from the top
of this packet.

=cut

sub insert_packet {
	my ( $self, $after_location, $packet ) = @_;
	my $top = $self->cut($after_location);
	my @new_cards;
	push @new_cards, @{ $top->cards }, @{ $packet->cards }, @{ $self->cards };
	$self->cards( \@new_cards );
}

=head2 cut

	my $new_packet = $self->cut(26);

Cuts off a packet from this packet/deck, resulting in fewer cards in this packet.  
The new packet is returned as an instance of VANAMBURG::Packet.

=cut	

sub cut {
	my ( $self, $how_many ) = @_;

	my @packet = splice @{ $self->cards }, 0, $how_many;
	my $new_packet = VANAMBURG::Packet->new;
	$new_packet->add_card(@packet);
	return $new_packet;
}

=head2 cut_and_complete

	# cut a deck exactly in the middle and place top on bottom.
	$self->cut_and_complete(26);
	
Cut of n number of cards from the top, and place this packet on the bottom.

=cut

sub cut_and_complete {
	my ( $self, $how_many ) = @_;
	my @packet = splice @{ $self->cards }, 0, $how_many;
	$self->add_card(@packet);
}

=head2 cut_and_take

Simulates cutting a packet from the top, completing the cut,
and taking the top card from the deck.  This deck/packet now
has one less card.  

The taken card is returned as an instance of VANAMBURG::Card.

=cut

sub cut_and_take {
	my ( $self, $cut_to_packet_location ) = @_;

	my $Packet_max_index = $#{ $self->cards };
	my $new_packet       = VANAMBURG::Packet->new;
	my $take             = $self->card_at_location($cut_to_packet_location);

	# put the bottm on the top
	push @{ $new_packet->cards },
	  @{ $self->cards }[ $cut_to_packet_location .. $Packet_max_index ];

	# put the top on the bottom
	push @{ $new_packet->cards },
	  @{ $self->cards }[ 0 .. $cut_to_packet_location - 2 ];
	$self->cards( $new_packet->cards );

	return $take;
}

=head2 cut_take_bury

This simulates cutting to a location, taking that card, placing it on the top,
and completing the cut, thus burying the taken card in the middle in a new 
location.

The 'taken' card, though it remains in the deck, is returned for 'peeking'.

=cut

sub cut_take_bury {
	my ( $self, $cut_to_packet_location ) = @_;

	my $Packet_max_index = $#{ $self->cards };
	my $new_packet       = VANAMBURG::Packet->new;
	my $take             = $self->card_at_location($cut_to_packet_location);

	# put the bottm on the top
	push @{ $new_packet->cards },
	  @{ $self->cards }[ $cut_to_packet_location .. $Packet_max_index ];

	# put bury card next
	push @{ $new_packet->cards }, $take;

	# put the top on the bottom
	push @{ $new_packet->cards },
	  @{ $self->cards }[ 0 .. $cut_to_packet_location - 2 ];
	$self->cards( $new_packet->cards );

	return $take;
}

=head2 location_of

Given a card, this method returns is location in the packet.  This is a
one-based index, familiar to a magician, not a 0 baded index, familiar
to a programmer.

=cut

sub location_of {
	my ( $self, $card ) = @_;
	for ( 0 .. $#{ $self->cards } ) {
		return $_ + 1 if ( $self->get_card($_)->equals($card) );
	}
}

=head2 bottom_card

Returns the bottom card of the packet for 'peeking'. The card remains 
in this deck.  The returned card is an instance of L<VANAMBURG::Card>.

=cut

sub bottom_card {
	my $self = shift;
	$self->get_card( $#{ $self->cards } );
}

=head2 top_card


Returns the top card of the packet for 'peeking'. The card remains 
in this deck. The returned card is an instance of L<VANAMBURG::Card>.

=cut

sub top_card {
	my $self = shift;
	$self->get_card(0);
}

=head2 card_at_location

Returns the card at a location.  This is a 1 based index, familiar to
the magician, not a 0 based index familiar to the programmer.  For
0 based access use get_card(index).

The returned card is an instance of L<VANAMBURG::Card>.

=cut

sub card_at_location {
	my ( $self, $Packet_location ) = @_;
	return $self->get_card( $Packet_location - 1 );
}

=head2 print_packet

Prints the display name and location to STDOUT.  Useful for console scripts only.

=cut

sub print_packet {
	my $self     = shift;
	my $location = 1;
	$self->map_cards(
		sub { printf "%02d %s\n", ( $location++, $_->display_name ); } );
}

=head2 to_abbreviation_csv_string

Returns a representation of the packet as a comma separated list of abbreviations (e.g., "AD,JS,2H")
which can be passed to L<VANAMBURG::PacketFactory::create_packet> or L<VANAMBURG::PacketFactory::create_stack>
to later re-instantiate the packet as objects.

=cut
 
sub to_abbreviation_csv_string {
	my $self = shift;
	my $result = join ',', map {
		$_->abbreviation
	} @{ $self->cards };
}
1;
