=head1 NAME

Time::TAI::Realisation_TAI - TAI as a realisation of TT

=head1 SYNOPSIS

	use Time::TAI::Realisation_TAI;

	$rln = Time::TAI::Realisation_TAI->new;

	$tai_instant = $rln->to_tai($instant);
	$instant = $rln->from_tai($tai_instant);
	$rln1_instant = $rln0->to_realisation($rln1, $rln0_instant);
	$rln0_instant = $rln0->from_realisation($rln1, $rln1_instant);

=head1 DESCRIPTION

This class implements the realisation of Terrestrial Time (TT) provided
by International Atomic Time (TAI).  See L<Time::TT::Realisation> for
the interface.

=cut

package Time::TAI::Realisation_TAI;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.003";

use parent "Time::TT::Realisation";

=head1 CONSTRUCTOR

Normally one won't use this constructor directly.  See the
C<tt_realisation> function in L<Time::TT>.

=over

=item Time::TAI::Realisation_TAI->new

Returns the sole object of this class.

=cut

my $instance = bless({});
sub new { $instance }

=back

=head1 METHODS

=over

=item $rln->to_tai(INSTANT)

=item $rln->from_tai(TAI_INSTANT)

These methods are part of the standard C<Time::TT::Realisation> interface.

=cut

sub to_tai { $_[1] }
*from_tai = \&to_tai;

=back

=head1 SEE ALSO

L<Time::TT>,
L<Time::TT::Realisation>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2010 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
