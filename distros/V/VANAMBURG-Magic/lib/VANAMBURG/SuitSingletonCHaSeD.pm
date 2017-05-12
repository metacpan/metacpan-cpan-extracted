package VANAMBURG::SuitSingletonCHaSeD;
use MooseX::Singleton;
use VANAMBURG::OrderedSuit;
use strict;
use warnings;
use v5.10;

=head1 VANAMBURG::SuitSingletonCHaSeD

Provides access to instances of VANAMBURG::OrderedSuit to 
efficiently represent the suits in a CHaSeD style deck stack.

=cut

=head2 spade

An instance of VANAMBURG::OrderedSuit to efficiently represent
the Spades suit in a CHaSeD stack.

=cut

has 'spade' => (
    isa     => 'VANAMBURG::OrderedSuit',
    is      => 'ro',
    default => sub {
        return VANAMBURG::OrderedSuit->new(
            name         => "Spades",
            value        => 3,
            unicode_char => "\x{2660}",
            abbreviation => 'S'
        );
    }
);

=head2 heart

An instance of VANAMBURG::OrderedSuit to efficiently represent
the Hearts suit in a CHaSeD stack.

=cut

has 'heart' => (
    isa     => 'VANAMBURG::OrderedSuit',
    is      => 'ro',
    default => sub {
        VANAMBURG::OrderedSuit->new(
            name         => "Hearts",
            value        => 2,
            unicode_char => "\x{2661}",
            abbreviation => 'H'
        );
    }
);

=head2 club

An instance of VANAMBURG::OrderedSuit to efficiently represent
the Clubs suit in a CHaSeD stack.

=cut

has 'club' => (
    isa     => 'VANAMBURG::OrderedSuit',
    is      => 'ro',
    default => sub {
        VANAMBURG::OrderedSuit->new(
            name         => "Clubs",
            value        => 1,
            unicode_char => "\x{2663}",
            abbreviation => 'C'
        );
    }
);

=head2 diamond

An instance of VANAMBURG::OrderedSuit to efficiently represent
the Diamonds suit in a CHaSeD stack.

=cut

has 'diamond' => (
    isa     => 'VANAMBURG::OrderedSuit',
    is      => 'ro',
    default => sub {
        VANAMBURG::OrderedSuit->new(
            name         => "Diamonds",
            value        => 4,
            unicode_char => "\x{2662}",
            abbreviation => 'D'
        );
    }
);

=head2 suit_cycle

An array reference holding each of the suit instances in an ordered in CHaSeD order.

=cut


has 'suit_cycle' => (
	is      => 'ro',
	lazy    => 1,
	isa     => 'ArrayRef[VANAMBURG::OrderedSuit]',
	default => sub {
		my $self = shift;
		[ $self->club, $self->heart, $self->spade, $self->diamond ];
	}
);

=head2 opposite_suit

Returns the mate of the card passed as input.

    my $heart = $self->opposite_suit($self->diamond);

=cut

sub opposite_suit {
	my ( $self, $suit ) = @_;
	given ( $suit->name ) {
		when ( $_ eq $self->spade->name )   { return $self->club; }
		when ( $_ eq $self->heart->name )   { return $self->diamond; }
		when ( $_ eq $self->club->name )    { return $self->spade; }
		when ( $_ eq $self->diamond->name ) { return $self->heart; }
	}
}

=head2 next_suit

Returns the suit following the input suit for a CHaSeD packet.

    my $diamond = $self->next_suit($self->spade);
    my $club    = $self->next_suit($self->diamond);
    
=cut

sub next_suit {
	my ( $self, $suit ) = @_;
	given ( $suit->name ) {
		when ( $_ eq $self->club->name )    { return $self->heart; }
		when ( $_ eq $self->heart->name )   { return $self->spade; }
		when ( $_ eq $self->spade->name )   { return $self->diamond; }
		when ( $_ eq $self->diamond->name ) { return $self->club; }
	}
}

=head2 previous_suit

Returns the suit preceding the input suit for a CHaSeD packet.

    my $diamond   = $self->previous_suit($self->club);
    my $heart     = $self->previous_suit($self->spade);
    
=cut

sub previous_suit {
	my ( $self, $suit ) = @_;
	given ( $suit->name ) {
		when ( $_ eq $self->club->name )    { return $self->diamond; }
		when ( $_ eq $self->heart->name )   { return $self->club; }
		when ( $_ eq $self->spade->name )   { return $self->heart; }
		when ( $_ eq $self->diamond->name ) { return $self->spade; }
	}
}

1;
