package VANAMBURG::FaceValueSingleton;
use MooseX::Singleton;
use VANAMBURG::FaceValue;
use strict;
use warnings;
use Carp qw/croak/;
use v5.10;

=head2 VANAMBURG::FaceValueSingleton

Provides efficient access to instances of VANAMBURG::FaceValue objects that can 
be reused to create cards.  Attempts to provide memory and processor efficiency by
allowing reuse of FaceValue object rather than creating new ones everytime they are needed.

=cut

=head2 ace

Returns the instance of VANAMBURG::FaceValue that represents an Ace.
			name         => "Ace",
			value        => 1,
			abbreviation => 'A'

=cut

has 'ace' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	lazy    => 0,
	default => sub {
		return VANAMBURG::FaceValue->new(
			name         => "Ace",
			value        => 1,
			abbreviation => 'A'
		);
	}
);

=head2 two

Returns the instance of VANAMBURG::FaceValue that represents a Two.
			name         => "Two",
			value        => 2,
			abbreviation => '2'

=cut

has 'two' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Two",
			value        => 2,
			abbreviation => '2'
		);
	}
);

=head2 two

Returns the instance of VANAMBURG::FaceValue that represents a Three.
			name         => "Three",
			value        => 3,
			abbreviation => '3'

=cut

has 'three' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Three",
			value        => 3,
			abbreviation => '3'
		);
	}
);

=head2 two

Returns the instance of VANAMBURG::FaceValue that represents a Four.
			name         => "Four",
			value        => 4,
			abbreviation => '4'

=cut

has 'four' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Four",
			value        => 4,
			abbreviation => '4'
		);
	}
);

=head2 two

Returns the instance of VANAMBURG::FaceValue that represents a Five.
			name         => "Five",
			value        => 5,
			abbreviation => '5'

=cut

has 'five' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Five",
			value        => 5,
			abbreviation => '5'
		);
	}
);

=head2 six

Returns the instance of VANAMBURG::FaceValue that represents a Six.
			name         => "Six",
			value        => 6,
			abbreviation => '6'

=cut

has 'six' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Six",
			value        => 6,
			abbreviation => '6'
		);
	}
);

=head2 seven

Returns the instance of VANAMBURG::FaceValue that represents a Seven.
			name         => "Seven",
			value        => 7,
			abbreviation => '7'

=cut

has 'seven' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Seven",
			value        => 7,
			abbreviation => '7'
		);
	}
);

=head2 eight

Returns the instance of VANAMBURG::FaceValue that represents a Eight.
			name         => "Eight",
			value        => 8,
			abbreviation => '8'

=cut

has 'eight' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Eight",
			value        => 8,
			abbreviation => '8'
		);
	}
);

=head2 nine

Returns the instance of VANAMBURG::FaceValue that represents a Nine.
			name         => "Nine",
			value        => 9,
			abbreviation => '9'

=cut

has 'nine' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Nine",
			value        => 9,
			abbreviation => '9'
		);
	}
);

=head2 ten

Returns the instance of VANAMBURG::FaceValue that represents a Ten.
			name         => "Ten",
			value        => 10,
			abbreviation => '10'

=cut

has 'ten' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Ten",
			value        => 10,
			abbreviation => '10'
		);
	}
);

=head2 jack

Returns the instance of VANAMBURG::FaceValue that represents a Jack.
			name         => "Jack",
			value        => 11,
			abbreviation => 'J'

=cut

has 'jack' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Jack",
			value        => 11,
			abbreviation => 'J'
		);
	}
);

=head2 queen

Returns the instance of VANAMBURG::FaceValue that represents a Queen.
			name         => "Queen",
			value        => 12,
			abbreviation => 'Q'

=cut

has 'queen' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "Queen",
			value        => 12,
			abbreviation => 'Q'
		);
	}
);

=head2 king

Returns the instance of VANAMBURG::FaceValue that represents a King.
			name         => "King",
			value        => 13,
			abbreviation => 'K'

=cut

has 'king' => (
	isa     => 'VANAMBURG::FaceValue',
	is      => 'ro',
	default => sub {
		VANAMBURG::FaceValue->new(
			name         => "King",
			value        => 13,
			abbreviation => 'K'
		);
	}
);

=head2 default_value_cycle

Returns an array reference containing all the FaceValue instances in order A - K.

=cut

has 'default_value_cycle' => (
	is      => 'rw',
	lazy    => 1,
	isa     => 'ArrayRef[VANAMBURG::FaceValue]',
	default => sub {
		my $self = shift;

		my @result = (
			$self->ace,  $self->two, $self->three, $self->four,
			$self->five, $self->six, $self->seven, $self->eight,
			$self->nine, $self->ten, $self->jack,  $self->queen,
			$self->king
		);
		return \@result;
	}
);

=head2 facevalue_by_abbreviation

Given a face value abbreviation ("A","2", "J", etc.) this method returns the appropriate singleton for the FaceValue.

=cut

sub facevalue_by_abbreviation {
	my ( $self, $abbrev ) = @_;
	$abbrev = uc $abbrev;
	croak "Invalid suit abbreviation: $abbrev" if ( $abbrev !~ /(A|2|3|4|5|6|7|8|9|10|J|Q|K)/ );

	state $lookup = {
		A  => $self->ace,
		2  => $self->two,
		3  => $self->three,
		4  => $self->four,
		5  => $self->five,
		6  => $self->six,
		7  => $self->seven,
		8  => $self->eight,
		9  => $self->nine,
		10 => $self->ten,
		J  => $self->jack,
		Q  => $self->queen,
		K  => $self->king
	};
	return $lookup->{$abbrev};
}

1;
