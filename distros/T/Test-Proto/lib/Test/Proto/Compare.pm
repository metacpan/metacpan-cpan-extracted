package Test::Proto::Compare;
use strict;
use warnings;
use Moo;
use Test::Proto::Common;
use overload
	'&{}' => \&compare,
	'""'  => sub { $_[0]->summary };

has 'code',
	is      => 'rw',
	default => sub {
	sub { $_[0] cmp $_[1] }
	};

has 'reversed',
	is      => 'rw',
	default => sub { 0 };

has 'summary',
	is      => 'rw',
	default => sub { 'cmp' };

around 'code', 'reversed', 'summary', \&Test::Proto::Common::chainable;

sub reverse {
	my $self = shift;
	$self->reversed( !$self->reversed );
	return $self;
}

sub compare {
	my ( $self, $A, $B ) = @_;
	if ( $self->reversed ) {
		return $self->code->( $B, $A );
	}
	else {
		return $self->code->( $A, $B );
	}
}

sub eq { shift->compare(@_) == 0 }
sub ne { shift->compare(@_) != 0 }

sub gt { shift->compare(@_) > 0 }
sub ge { shift->compare(@_) >= 0 }

sub lt { shift->compare(@_) < 0 }
sub le { shift->compare(@_) <= 0 }

sub BUILDARGS {
	my $class = shift;
	return { ( exists $_[0] ? ( code => $_[0] ) : () ) };
}

=head1 NAME

Test::Proto::Compare - wrapper for comparison functions

=head1 SYNOPSIS

	my $c = Test::Proto::Compare->new(sub {lc $_[0] cmp lc $_[1]});
	$c->summary('lc cmp');
	$c->compare($left, $right); # lc $left cmp $right
	$c->reverse->compare($left, $right); # lc $right cmp lc $left

This class provides a wrapper for comparison functions so they can be identified by formatters.

=head1 METHODS

=head3 new

If an argument is passed, it replaces the C<code> attribute.

=head3 code

Chainable attribute containing the comparison code itself.

=head3 compare

Executes the comparison code, using reversed to determine whether to reverse the arguments.

=head3 summary

Chainable attribute; a brief human-readable description of the operation which will be performed. Default is 'cmp'.

=head3 reversed

Chainable attribute. 1 if the comparison is reversed, 0 otherwise. Default is 0. Also a chainable setter.

=head3 reverse

A chainable method which takes no arguments, and causes C<reversed> to be either 1 or 0 (whichever it previously wasn't).

=head3 eq, ne, gt, lt, ge, le

These run compare and return a true or false value depending on what compare returned.

=cut

1;
