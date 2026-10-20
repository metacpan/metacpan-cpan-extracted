package Time::Keeper::Star::Day;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper::Sky;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Star::Day - a star's rises, sets and transits on one civil day at a place

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
    my $d = Time::Keeper::Star->on($date, 'Sirius', place => $sky);
    my $d = $sky->on($date, 'Sirius');          # the same

    $d->rise;  $d->set;  $d->transit;          # values, or undef
    $d->body;                                 # 'Sirius'
    $d->hr;                                   # 2491
    $d->is_up_all_day;                        # Polaris from London

=head1 DESCRIPTION

The day is the place's civil day, as L<Time::Keeper::Sun/THE DAY> describes it. A star
rises and sets when its centre, seen from the place, is 34 arcminutes below the
horizon, as for a planet (L<Time::Keeper::Planet::Day>). A star keeps sidereal time:
its events come 3 minutes 56 seconds earlier each day, and a civil day can hold two
transits. A star whose distance from the pole is less than the place's latitude never
sets (C<is_up_all_day>); one as far from the other pole never rises
(C<is_down_all_day>).

=head1 METHODS

A Time::Keeper::Star::Day is a L<Time::Keeper::Body::Day>, whose methods it has:
C<rise>, C<set>, C<transit>, C<rises>, C<sets>, C<transits>, C<events>,
C<is_up_all_day>, C<is_down_all_day>, C<body>, C<date>, C<zone_name>, C<start>,
C<end> and C<place>. And:

=head2 hr

The star's number in the Bright Star Catalogue.

=head1 SEE ALSO

L<Time::Keeper::Star>, L<Time::Keeper::Body::Day>, L<Time::Keeper::Sky>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
