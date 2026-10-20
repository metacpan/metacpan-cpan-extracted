package Time::Keeper::Natural::Match;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

use Time::Keeper::Natural ();

1;

__END__

=head1 NAME

Time::Keeper::Natural::Match - what a text named, and what was filled in

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $m = Time::Keeper::Natural->new(zone => 'Europe/London')->match('next Tuesday at 3 pm');
    $m->value;        # 2026-10-20T15:00:00+01:00
    $m->kind;         # point
    $m->precision;    # hour
    $m->assumed;      # ('zone')

=head1 DESCRIPTION

A natural phrase leaves things out: "15 October" has no year, "next month"
names a period and not an instant, "Tuesday" has no direction. A Match holds
the value read and a list of what was assumed to make it one. It is made by
L<Time::Keeper::Natural/match> and its three siblings and never by hand, and
it cannot be changed.

=head1 METHODS

=head2 value

The Time::Keeper value, Time::Keeper::Date or Time::Keeper::Duration read;
for an interval, its start.

=head2 kind

C<point> (from C<match>), C<date> (C<match_date>), C<duration>
(C<match_duration>) or C<interval> (C<match_interval>).

=head2 to

An interval's end; C<undef> for the other kinds. (C<end> is where the text
ends.)

=head2 precision

The smallest field the text named: C<year>, C<quarter>, C<month>, C<week>,
C<day>, C<hour>, C<minute>, C<second>, or a fraction of one; C<none> for a
duration. "next month" is C<month>, "next Tuesday at 3 pm" C<hour>, "15:30"
C<minute>, "now" C<second>. An interval's is its start's.

=head2 assumed

What was filled in, as a list of fixed strings, empty when the text left
nothing out:

    year             a date with no year took the anchor's (or prefer's)
    month            a day with no month ("the 15th") took the anchor's (or prefer's)
    century          a two-digit year took the nearest century
    date             a time with no date is on the anchor's day
    time             a day named without a time is its first moment
    period start     a period longer than a day is its first moment
    weekday next     a bare weekday is the coming one
    weekday last     ... or, under prefer => 'past', the last one
    direction        a phrase with two meanings took prefer's side
    bare_hour am     a bare hour in a twelve-hour locale, by the option
    bare_hour pm
    bare_hour next
    zone             the text named no zone; the parser's was used

=head2 assumptions

    Time::Keeper::Natural::Match->assumptions;

That list, the whole of it, in that order. A Match never carries another.

=head2 text

The text as given.

=head2 start

=head2 end

Where in the text what was read begins and ends, in characters: the text
without its outer whitespace, since a text is read whole or not at all.

=head2 locale

The locale whose words were read.

=head2 anchor

The anchor the text was read against.

=head1 SEE ALSO

L<Time::Keeper::Natural>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
