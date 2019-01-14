package Test::Mocha::Method;
# ABSTRACT: Objects to represent methods and their arguuments
$Test::Mocha::Method::VERSION = '0.65';
use strict;
use warnings;

# smartmatch dependencies
use 5.010001;
use experimental 'smartmatch';

use Carp 'croak';
use Devel::PartialDump 0.17 ();
use Scalar::Util qw( blessed looks_like_number refaddr );
use Test::Mocha::Types qw( Matcher Slurpy );
use Test::Mocha::Util 'check_slurpy_arg';
use Types::Standard qw( ArrayRef HashRef Str );

use overload '""' => \&stringify, fallback => 1;

# cause string overloaded objects (Matchers) to be stringified
my $Dumper = Devel::PartialDump->new( objects => 0, stringify => 1 );

sub new {
    # uncoverable pod
    my ( $class, %args ) = @_;
    ### assert: Str->check( $args{name} )
    ### assert: ArrayRef->check( $args{args} )
    return bless \%args, $class;
}

sub name {
    # uncoverable pod
    return $_[0]->{name};
}

sub args {
    # uncoverable pod
    return @{ $_[0]->{args} };
}

sub stringify {
    # """
    # Stringifies this method call to something that roughly resembles what
    # you'd type in Perl.
    # """
    # uncoverable pod
    my ($self) = @_;
    return $self->name . '(' . $Dumper->dump( $self->args ) . ')';
}

sub __satisfied_by {
    # """
    # Returns true if the given C<$invocation> satisfies this method call.
    # """
    # uncoverable pod
    my ( $self, $invocation ) = @_;

    return unless $invocation->name eq $self->name;

    my @expected = $self->args;
    my @input    = $invocation->args;
    # invocation arguments can't be argument matchers
    ### assert: ! grep { Matcher->check($_) } @input
    check_slurpy_arg(@expected);

    # match @input against @expected which may include argument matchers
    while ( @input && @expected ) {
        my $matcher = shift @expected;

        # slurpy argument matcher
        if ( Slurpy->check($matcher) ) {
            $matcher = $matcher->{slurpy};
            ### assert: $matcher->is_a_type_of(ArrayRef) || $matcher->is_a_type_of(HashRef)

            my $value;
            if ( $matcher->is_a_type_of(ArrayRef) ) {
                $value = [@input];
            }
            elsif ( $matcher->is_a_type_of(HashRef) ) {
                return unless scalar(@input) % 2 == 0;
                $value = {@input};
            }
            # else { invalid matcher type }
            return unless $matcher->check($value);

            @input = ();
        }
        # argument matcher
        elsif ( Matcher->check($matcher) ) {
            return unless $matcher->check( shift @input );
        }
        # literal match
        else {
            return unless _match( shift(@input), $matcher );
        }
    }

    # slurpy matcher should handle empty argument lists
    if ( @expected > 0 && Slurpy->check( $expected[0] ) ) {
        my $matcher = shift(@expected)->{slurpy};

        my $value;
        if ( $matcher->is_a_type_of(ArrayRef) ) {
            $value = [@input];
        }
        elsif ( $matcher->is_a_type_of(HashRef) ) {
            return unless scalar(@input) % 2 == 0;
            $value = {@input};
        }
        # else { invalid matcher type }
        return unless $matcher->check($value);
    }

    return @input == 0 && @expected == 0;
}

sub _match {
    # """Match 2 values for equality."""
    # uncoverable pod
    my ( $x, $y ) = @_;

    # This function uses smart matching, but we need to limit the scenarios
    # in which it is used because of its quirks.

    # ref types must match
    return if ref $x ne ref $y;

    # objects match only if they are the same object
    if ( blessed($x) || ref($x) eq 'CODE' ) {
        return refaddr($x) == refaddr($y);
    }

    # don't smartmatch on arrays because it recurses
    # which leads to the same quirks that we want to avoid
    if ( ref($x) eq 'ARRAY' ) {
        return if $#{$x} != $#{$y};

        # recurse to handle nested structures
        foreach ( 0 .. $#{$x} ) {
            return if !_match( $x->[$_], $y->[$_] );
        }
        return 1;
    }

    if ( ref($x) eq 'HASH' ) {
        # smartmatch only matches the hash keys
        return if not $x ~~ $y;

        # ... but we want to match the hash values too
        foreach ( keys %{$x} ) {
            return if !_match( $x->{$_}, $y->{$_} );
        }
        return 1;
    }

    # avoid smartmatch doing number matches on strings
    # e.g. '5x' ~~ 5 is true
    return if looks_like_number($x) xor looks_like_number($y);

    return $x ~~ $y;
}

1;
