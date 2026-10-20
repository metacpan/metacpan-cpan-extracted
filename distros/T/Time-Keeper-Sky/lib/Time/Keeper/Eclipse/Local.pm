package Time::Keeper::Eclipse::Local;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper::Sky;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Eclipse::Local - a solar eclipse as one place sees it

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $l = Time::Keeper::Eclipse->next(kind => 'solar', after => $t)->local(place => $sky);
    $l->type;                       # partial | annular | total, there
    $l->maximum;                    # a Time::Keeper value
    $l->magnitude;  $l->obscuration;
    for ($l->contacts) { my ($name, $when, $altitude, $azimuth) = @$_ }   # c1 c2 c3 c4
    $l->duration;                   # of totality or annularity there, or undef
    $l->is_seen;                    # the sun up for some of it

=head1 METHODS

=head2 type

C<partial>, C<annular> or C<total> at the place.

=head2 maximum

The instant the sun's and the moon's centres are nearest, seen from the place, in
the place's zone.

=head2 magnitude

The fraction of the sun's diameter covered at the maximum (over 1 in a total eclipse).

=head2 obscuration

The fraction of the sun's disc covered at the maximum, by area.

=head2 contacts

The contacts, in order, as C<[name, value, altitude, azimuth]> with the sun's
apparent altitude and azimuth there: C<c1> and C<c4>, the discs first and last
touching; C<c2> and C<c3>, totality's or annularity's beginning and end. A contact may
fall with the sun below the horizon: its altitude says so.

=head2 contact

    my $c2 = $l->contact('c2');     # undef in a partial eclipse

=head2 duration

The duration of totality or annularity, a L<Time::Keeper::Duration>, or undef.

=head2 sun_at_maximum

    my ($altitude, $azimuth) = $l->sun_at_maximum;

=head2 is_seen

Whether the sun is up at some time between C1 and C4.

=head1 SEE ALSO

L<Time::Keeper::Eclipse>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
