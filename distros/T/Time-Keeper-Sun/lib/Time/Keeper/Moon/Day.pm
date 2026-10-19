package Time::Keeper::Moon::Day;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

use Time::Keeper::Sun;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Moon::Day - the moon on one civil day in a zone

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $day = Time::Keeper::Moon->on($date, zone => 'Europe/London');

    $day->phase_name;        # full, or waning_gibbous
    $day->phase;             # the full moon's value, or undef
    $day->illumination;      # at local noon
    $day->age;               # days, at local noon

=head1 DESCRIPTION

What L<Time::Keeper::Moon/on> gives: the moon on one civil day in the zone, which runs
from the midnight the zone had to the next.

=head1 METHODS

=head2 phase_name

The principal phase that falls in the day (C<new>, C<first_quarter>, C<full>,
C<last_quarter>), when one does; else the name of the stretch the day lies in
(C<waxing_crescent>, C<waxing_gibbous>, C<waning_gibbous>, C<waning_crescent>). So
the day a new moon falls on is C<new> wherever in the day it falls, and the days either
side are crescents.

=head2 phase

The principal phase's value, in the zone, or undef when none falls in the day.

=head2 illumination

=head2 age

The fraction of the disk lit, and the days since the last new moon, both at local noon
(the first moment after it where the clocks skipped it).

=head2 moonrise

=head2 moonset

=head2 moon_transit

The first moonrise, moonset or upper transit in the day, or undef; the day must have
been made with a place, or these die naming it. See L<Time::Keeper::Moon/THE MOON'S DAY>.

=head2 moonrises

=head2 moonsets

=head2 moon_transits

Every one of the kind in the day, in order: none, one or two.

=head2 is_moon_up_all_day

=head2 is_moon_down_all_day

True when the moon neither rose nor set in the day and was above, or below, the horizon
throughout.

=head2 events

Every event of the day in order of time, each a reference to a two-element array of its
name and value: the principal phase (C<new>, C<first_quarter>, C<full>,
C<last_quarter>) when one falls in the day, and with a place C<moonrise>, C<moonset>
and C<moon_transit>.

=head2 place

The L<Time::Keeper::Sun> place the day was made with, or undef when it was made without
one.

=head2 date

The day, as a L<Time::Keeper::Date>.

=head2 zone_name

The zone's name.

=head2 start

=head2 end

=head2 noon

The window's edges and its noon, as values.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
