package Set::Scalar::ValuedUniverse;

use strict;
local $^W = 1;

use vars qw($VERSION @ISA);

$VERSION = '1.29';
@ISA = qw(Set::Scalar::Virtual Set::Scalar::Base);

use Set::Scalar::Virtual;
use Set::Scalar::Null;

my $UNIVERSE = __PACKAGE__->new;

sub SET_FORMAT        { "[%s]" }

sub universe {
    my $self = shift;

    return $UNIVERSE;
}

sub null {
    my $self = shift;
    return Set::Scalar::Null->new( $self );
}

=pod

=head1 NAME

Set::Scalar::ValuedUniverse - universes for valued set members

=head1 SYNOPSIS

B<Do not use directly.>

=head1 DESCRIPTION

There are only two guaranteed interfaces, both sort of indirect.

The first one is accessing the universe of a valued set:

    $valued_set->universe

This contains the members of the universe

    $valued_set->universe->members

of the C<$valued_set>.

The second supported interface is displaying universes of valued sets.

    print $valued_set->universe, "\n";

This will display the members of the valued set inside square brackets: [],
as opposed to valued sets, which have their members shown inside
parentheses: ().

=head1 AUTHOR

Jarkko Hietaniemi <jhi@iki.fi>

=cut

1;
