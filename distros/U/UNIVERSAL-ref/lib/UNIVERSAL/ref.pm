package UNIVERSAL::ref;
BEGIN {
  $UNIVERSAL::ref::VERSION = '0.14';
}
use strict;
use warnings;
use B::Utils;

our @hooked;
our @needs_truth = qw(overload);

sub import {
    my $class = caller;
    my %unique;
    @hooked = grep { !$unique{$_}++ } ( @hooked, $class );
}

sub unimport {
    my $class = caller;
    @hooked = grep $_ ne $class, @hooked;
}

my $DOES;
BEGIN { $DOES = UNIVERSAL->can('DOES') ? 'DOES' : 'isa' }

sub _hook {

    # Below, you'll see that there is special dispensation for never
    # hooking the function named UNIVERSAL::ref::_hook. That's why this
    # ref() is safe from predation by this module.

    # Is this object asserting that it is an ancestor of any hooked class?
    my $is_hooked;
    my $obj_class    = CORE::ref $_[0];
    my $caller_class = caller;

    # For any special classes needing truth, just return if we've got
    # any of those.
    for my $class (@needs_truth) {
        if ( $caller_class->$DOES($class) ) {

            # CORE::ref
            return $obj_class;
        }
    }

    #
    for my $hooked_class (@hooked) {

        # Find only hooked ancestries that pertain this object.
        next unless $obj_class->$DOES($hooked_class);

        # Check that the call wasn't made from within this object's
        # ancestry. It has to be possible for an object to ask
        # questions about itself without getting lies.
        next if $obj_class->$DOES($caller_class);

        return $_[0]->ref;
    }

    # CORE::ref
    return $obj_class;
}

use XSLoader;
$| = 1;
XSLoader::load( 'UNIVERSAL::ref', $UNIVERSAL::ref::VERSION );

use B 'svref_2object';
use B::Utils 'all_roots';
my %roots = all_roots();
for my $nm ( sort keys %roots ) {
    my $op = $roots{$nm};

    next unless $$op;
    next if $nm eq 'UNIVERSAL::ref::_hook';

    if ( defined &$nm ) {
        my $cv = svref_2object( \&$nm );
        next unless ${ $cv->ROOT };
        next unless ${ $cv->START };
    }

    _fixupop($op);
}

no warnings;
q[Let's Make Love and Listen to Death From Above];

__END__

=head1 NAME

UNIVERSAL::ref - Turns ref() into a multimethod

=head1 SYNOPSIS

  # True! Wrapper pretends to be Thing.
  ref( Wrapper->new( Thing->new ) )
    eq ref( Thing->new );

  package Thing;
  sub new { bless [], shift }

  package Wrapper;
  sub new {
      my ($class,$proxy) = @_;
      bless \ $proxy, $class;
  }
  sub ref {
      my $self = shift @_;
      return $$self;
  }

=head1 DESCRIPTION

This module changes the behavior of the builtin function ref(). If
ref() is called on an object that has requested an overloaded ref, the
object's C<< ->ref >> method will be called and its return value used
instead.

=head1 USING

To enable this feature for a class, C<use UNIVERSAL::ref> in your
class. Here is a sample proxy module.

  package Pirate;
  # Pirate pretends to be a Privateer
  use UNIVERSAL::ref;
  sub new { bless {}, shift }
  sub ref { return 'Privateer' }

Anywhere you call C<ref($obj)> on a C<Pirate> object, it will allow
C<Pirate> to lie and pretend to be something else.

=head1 METHODS

=over

=item import

A pragma for ref()-enabling your class. This adds the calling class
name to a global list of ref()-enabled classes.

    package YourClass;
    use UNIVERSAL::ref;
    sub ref { ... }

=item unimport

A pragma for ref()-disabling your class. This removes the calling
class name from a global list of ref()-enabled classes.

=back

=head1 TODO

Currently UNIVERSAL::ref must be installed before any ref() calls that
are to be affected.

I think ref() always occurs in an implicit scalar context. There is no
accomodation for list context.

UNIVERSAL::ref probably shouldn't allow a module to lie to itself. Or
should it?

=head1 ACKNOWLEDGEMENTS

ambrus for the excellent idea to overload defined() to allow Perl 5 to
have Perl 6's "interesting values of undef."

chromatic for pointing out how utterly broken ref() is. This fix
covers its biggest hole.

=head1 AUTHOR

Joshua ben Jore - jjore@cpan.org

=head1 LICENSE

The standard Artistic / GPL license most other perl code is typically
using.
