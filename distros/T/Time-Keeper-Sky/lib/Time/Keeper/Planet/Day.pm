package Time::Keeper::Planet::Day;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper::Planet;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Planet::Day - a planet's rises, sets and transits on one civil day at a place

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
    my $d = Time::Keeper::Planet->on($date, 'venus', place => $sky);

    $d->rise;  $d->set;  $d->transit;       # values, or undef
    $d->rises;  $d->sets;  $d->transits;    # all of them in the day
    $d->events;                             # ([rise => value], [transit => value], ...)
    $d->is_up_all_day;  $d->is_down_all_day;
    $d->planet;                             # 'venus'

=head1 DESCRIPTION

The day is the place's civil day, as L<Time::Keeper::Sun/THE DAY> describes it. A
planet rises when its centre, seen from the place, is 34 arcminutes below the horizon
(refraction's; a planet is a point, and its half-diameter of under half a minute of
arc is left out, as the U.S. Naval Observatory leaves it out), with the dip of the
horizon from a height, as for the sun. A planet keeps nearly the stars' time, so its
events come about four minutes earlier each day, and a civil day can hold two
transits or none.

=head1 METHODS

A Time::Keeper::Planet::Day is a L<Time::Keeper::Body::Day>, whose methods it has:
C<rise>, C<set>, C<transit>, C<rises>, C<sets>, C<transits>, C<events>,
C<is_up_all_day>, C<is_down_all_day>, C<body>, C<date>, C<zone_name>, C<start>,
C<end> and C<place>. And:

=head2 planet

The planet's name, as C<body> gives it.

=head1 SEE ALSO

L<Time::Keeper::Planet>, L<Time::Keeper::Body::Day>, L<Time::Keeper::Sky>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
