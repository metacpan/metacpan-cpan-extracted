=head1 NAME

Time::TT::InterpolatingRealisation - TT realised by interpolation

=head1 SYNOPSIS

	use Time::TT::InterpolatingRealisation;

	$rln = Time::TT::InterpolatingRealisation->new($interpolator);

	$tai_instant = $rln->to_tai($instant);
	$instant = $rln->from_tai($tai_instant);
	$rln1_instant = $rln0->to_realisation($rln1, $rln0_instant);
	$rln0_instant = $rln0->from_realisation($rln1, $rln1_instant);

=head1 DESCRIPTION

This class implements a realisation of Terrestrial Time (TT) by
interpolation between known points of correlation between the realisation
and International Atomic Time (TAI).  See L<Time::TT::Realisation>
for the interface.

=cut

package Time::TT::InterpolatingRealisation;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.005";

use Time::TT::Realisation 0.005 ();
use parent "Time::TT::Realisation";

=head1 CONSTRUCTOR

Normally one won't use this constructor directly.  See the
C<tt_realisation> function in L<Time::TT>, which will construct a range
of published realisations, most of which are implemented using this class.
Use this directly only if the realisation that you desire is not available
by that means.

=over

=item Time::TT::InterpolatingRealisation->new(INTERPOLATOR)

Constructs and returns an object representing a realisation of
TT that is defined by isolated points of correlation between it
and TAI.  The INTERPOLATOR argument must be an object of a subclass
of C<Math::Interpolator>, supplying the C<x> and C<y> methods.  The x
coordinate of the interpolator's curve must represent TAI, and the y
coordinate the realisation of interest.  Times on both coordinates are
represented as the number of seconds since the 1958 epoch, as described
in L<Time::TT>.  All numbers must be C<Math::BigRat> objects.

The class C<Time::TT::OffsetKnot> may be useful in building the required
interpolator.

=cut

sub new {
	my($class, $interpolator) = @_;
	return bless(\$interpolator, $class);
}

=back

=head1 METHODS

=over

=item $rln->to_tai(INSTANT)

=item $rln->from_tai(TAI_INSTANT)

These methods are part of the standard C<Time::TT::Realisation> interface.

=cut

sub to_tai {
	my($self, $t) = @_;
	return ${$self}->x($t);
}

sub from_tai {
	my($self, $t) = @_;
	return ${$self}->y($t);
}

=back

=head1 SEE ALSO

L<Math::BigRat>,
L<Math::Interpolator>,
L<Time::TT>,
L<Time::TT::OffsetKnot>,
L<Time::TT::Realisation>

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
