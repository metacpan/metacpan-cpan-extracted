=head1 NAME

Time::TCG::Realisation - realisation of Geocentric Coordinate Time

=head1 SYNOPSIS

	use Time::TCG::Realisation;

	$rln = Time::TCG::Realisation->new($tt_rln);
	$tt_rln = $rln->tcg_tt_realisation;

	$tcg_tai_instant = $rln->to_tcg_tai($tcg_k_instant);
	$tcg_k_instant = $rln->from_tcg_tai($tcg_tai_instant);

	$rln1_instant = $rln0->to_realisation($rln1, $rln0_instant);
	$rln0_instant = $rln0->from_realisation($rln1, $rln1_instant);

=head1 DESCRIPTION

Geocentric Coordinate Time (TCG) is a platonic time scale, consisting of the
time axis of a relativistic reference frame comoving with the Terran
geocentre.  It is not directly accessible for practical use.  Instead,
it must be realised by the use of atomic clocks and other equipment.
A realisation is inevitably imperfect, only approximating the true TCG.
Consequently there are many realisations, with differing degrees of
accuracy and accessibility.

An object of this class represents a realisation of TCG.  Because TCG
has a precisely-defined relationship to Terrestrial Time (TT), anything
that realises one of these scales implicitly also realises the other.
Because of this every realisation of TCG is implemented using an
underlying realisation of TT.

In this interface, instants on the TCG scale are represented as a scalar
number of seconds since the TCG epoch, as described in L<Time::TCG>.
All such numbers are represented as C<Math::BigRat> objects.

=cut

package Time::TCG::Realisation;

{ use 5.006; }
use warnings;
use strict;

use Time::TCG 0.002 qw(tcg_to_tt tt_to_tcg);

our $VERSION = "0.002";

=head1 CONSTRUCTOR

=over

=item Time::TCG::Realisation->new(TT_REALISATION)

Creates and returns a new TCG realisation object based on the provided
TT realisation object.  The TT realisation object must be of type
C<Time::TT::Realisation>.

=cut

sub new {
	my($class, $tt_rln) = @_;
	return bless(\$tt_rln, $class);
}

=back

=head1 METHODS

=over

=item $rln->tcg_tt_realisation

Returns the TT realisation object underlying this TCG realisation.

=cut

sub tcg_tt_realisation { ${$_[0]} }

=item $rln->to_tcg_tai(INSTANT)

Takes an instant expressed on the time scale represented by this object,
and converts it to an instant on the TCG(TAI) scale.  The input must be
a C<Math::BigRat> object, and the result is the same type.

=cut

sub to_tcg_tai {
	my($self, $t) = @_;
	return tt_to_tcg($self->tcg_tt_realisation->to_tai(tcg_to_tt($t)));
}

=item $rln->from_tcg_tai(INSTANT)

Takes an instant expressed on the TCG(TAI) scale, and converts it to an
instant on the time scale represented by this object.  The input must
be a C<Math::BigRat> object, and the result is the same type.

=cut

sub from_tcg_tai {
	my($self, $t) = @_;
	return tt_to_tcg($self->tcg_tt_realisation->from_tai(tcg_to_tt($t)));
}

=item $rln->to_realisation(REALISATION, INSTANT)

Takes an instant expressed on the time scale represented by this object,
and converts it to an instant on the time scale represented by the
REALISATION object (which must be another realisation of TCG).  The input
must be a C<Math::BigRat> object, and the result is the same type.

=cut

sub to_realisation {
	my($self, $rln, $t) = @_;
	return $t if $rln == $self;
	return tt_to_tcg($self->tcg_tt_realisation
			->to_realisation($rln->tcg_tt_realisation,
					 tcg_to_tt($t)));
}

=item $rln->from_realisation(REALISATION, INSTANT)

Takes an instant expressed on the time scale represented by the
REALISATION object (which must be another realisation of TCG), and
converts it to an instant on the time scale represented by this object.
The input must be a C<Math::BigRat> object, and the result is the
same type.

=cut

sub from_realisation {
	my($self, $rln, $t) = @_;
	return $t if $rln == $self;
	return tt_to_tcg($self->tcg_tt_realisation
			->from_realisation($rln->tcg_tt_realisation,
					   tcg_to_tt($t)));
}

=back

=head1 SEE ALSO

L<Time::TCG>,
L<Time::TT::Realisation>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2010, 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
