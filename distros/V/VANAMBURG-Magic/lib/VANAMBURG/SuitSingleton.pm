package VANAMBURG::SuitSingleton;
use MooseX::Singleton;
use VANAMBURG::Suit;
use strict;
use warnings;
use v5.10;
use Carp qw/croak/;

=head1 VANAMBURG::SuitSingleton

Provides singelton instances of VANAMBURG::Suit objects
for efficient use creating cards.

=cut

=head2 spade

Instance of VANAMBURG::Suit representing the Spades
suit.  
			name         => "Spades",
            unicode_char => "\x{2660}",
            abbreviation => 'S'
            
=cut
            
has 'spade' => (
    isa     => 'VANAMBURG::Suit',
    is      => 'ro',
    default => sub {
        return VANAMBURG::Suit->new(
            name         => "Spades",
            unicode_char => "\x{2660}",
            abbreviation => 'S'
        );
    }
);


=head2 heart

Instance of VANAMBURG::Suit representing the Hearts
suit.  
            name         => "Hearts",
            unicode_char => "\x{2661}",
            abbreviation => 'H'
            
=cut

has 'heart' => (
    isa     => 'VANAMBURG::Suit',
    is      => 'ro',
    default => sub {
        VANAMBURG::Suit->new(
            name         => "Hearts",
            unicode_char => "\x{2661}",
            abbreviation => 'H'
        );
    }
);


=head2 club

Instance of VANAMBURG::Suit representing the Clubs
suit.  
            name         => "Clubs",
            unicode_char => "\x{2663}",
            abbreviation => 'C'
            
=cut

has 'club' => (
    isa     => 'VANAMBURG::Suit',
    is      => 'ro',
    default => sub {
        VANAMBURG::Suit->new(
            name         => "Clubs",
            unicode_char => "\x{2663}",
            abbreviation => 'C'
        );
    }
);


=head2 diamond

Instance of VANAMBURG::Suit representing the Diamonds
suit.  
            name         => "Diamonds",
            unicode_char => "\x{2662}",
            abbreviation => 'D'
            
=cut

has 'diamond' => (
    isa     => 'VANAMBURG::Suit',
    is      => 'ro',
    default => sub {
        VANAMBURG::Suit->new(
            name         => "Diamonds",
            unicode_char => "\x{2662}",
            abbreviation => 'D'
        );
    }
);

=head2 suit_by_abbreviation

Given a suit abbreviation ("H","S", etc.) this method returns the appropriate singleton for the suit.

=cut

sub suit_by_abbreviation{
	my ($self, $abbrev) = @_;
	
	$abbrev = uc $abbrev;
	croak "Invalid suit abbreviation: $abbrev" if ($abbrev !~ /(S|H|C|D)/);
	
	state $lookup = {S => $self->spade, H => $self->heart, C => $self->club, D => $self->diamond};
	return $lookup->{$abbrev};
}


1;
