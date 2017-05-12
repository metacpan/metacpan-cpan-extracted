=head1 NAME

Time::TT::Realisation - realisation of Terrestrial Time (base class)

=head1 SYNOPSIS

	$tai_instant = $rln->to_tai($instant);
	$instant = $rln->from_tai($tai_instant);

	$rln1_instant = $rln0->to_realisation($rln1, $rln0_instant);
	$rln0_instant = $rln0->from_realisation($rln1, $rln1_instant);

=head1 DESCRIPTION

Terrestrial Time (TT) is a platonic time scale, consisting of the
time axis of a relativistic reference frame located on the Terran
geoid.  It is not directly accessible for practical use.  Instead,
it must be realised by the use of atomic clocks and other equipment.
A realisation is inevitably imperfect, only approximating the true TT.
Consequently there are many realisations, with differing degrees of
accuracy and accessibility.

An object of this class represents a realisation of TT.  The main
use of such an object is to convert between realisations in order to
determine the time of events with very high precision, in cases where
the directly-accessible realisation is not sufficiently accurate.

This is a base class, defining the interface for realisation objects.
If you already have a realisation object then this document is what
you should read in order to know how to use it.  If you don't have
a realisation object yet, there are no constructors here: see the
C<tt_realisation> function in L<Time::TT> or the C<tai_realisation>
function in L<Time::TAI>.  If you are implementing a subclass of
realisation object, see L</SUBCLASSING>.

The principal realisation of TT is International Atomic Time (TAI).
This is defined retrospectively, in monthly bulletins from the BIPM,
by its relation to real-time approximations of TAI that are supplied in
public time signals by tens of metrological agencies around the world.
Better realisations of TT are defined further in retrospect, and are
defined by their relation to TAI.  TAI thus has a pivotal role: different
realisations of TT can be related to each other by using TT(TAI) as an
intermediate form.

In this interface, instants on the TT scale are represented as a scalar
number of seconds since the TT epoch, as described in L<Time::TT>.
All such numbers are represented as C<Math::BigRat> objects.

=cut

package Time::TT::Realisation;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.005";

=head1 METHODS

=over

=item $rln->to_tai(INSTANT)

Takes an instant expressed on the time scale represented by this object,
and converts it to an instant on the TT(TAI) scale.  The input must be
a C<Math::BigRat> object, and the result is the same type.

=item $rln->from_tai(TAI_INSTANT)

Takes an instant expressed on the TT(TAI) scale, and converts it to an
instant on the time scale represented by this object.  The input must
be a C<Math::BigRat> object, and the result is the same type.

=item $rln->to_realisation(REALISATION, INSTANT)

Takes an instant expressed on the time scale represented by this object,
and converts it to an instant on the time scale represented by the
REALISATION object.  The input must be a C<Math::BigRat> object, and
the result is the same type.

=cut

sub to_realisation {
	my($self, $rln, $t) = @_;
	return $t if $rln == $self;
	return $rln->from_tai($self->to_tai($t));
}

=item $rln->from_realisation(REALISATION, INSTANT)

Takes an instant expressed on the time scale represented by the
REALISATION object, and converts it to an instant on the time scale
represented by this object.  The input must be a C<Math::BigRat> object,
and the result is the same type.

=cut

sub from_realisation {
	my($self, $rln, $t) = @_;
	return $t if $rln == $self;
	return $self->from_tai($rln->to_tai($t));
}

=back

=head1 SUBCLASSING

This class is designed to be subclassed, and cannot be instantiated alone.
Any subclass must implement the C<to_tai> and C<from_tai> methods.
That is the minimum required.  The general C<to_realisation> and
C<from_realisation> methods may also be implemented for cases that can
be done efficiently; they have default implementations in this class in
terms of C<to_tai> and C<from_tai>.

=head1 SEE ALSO

L<Time::TAI>,
L<Time::TT>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
