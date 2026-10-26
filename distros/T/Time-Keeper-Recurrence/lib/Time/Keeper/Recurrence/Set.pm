package Time::Keeper::Recurrence::Set;

use 5.010;
use strict;
use warnings;

use Time::Keeper::Recurrence;

our $VERSION = '0.03';

use overload
    '""'     => sub { $_[0]->ical },
    'bool'   => sub { 1 },
    fallback => 1;

1;

__END__

=head1 NAME

Time::Keeper::Recurrence::Set - rules with dates added and dates removed

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Time::Keeper::Recurrence;

    my $rule = Time::Keeper::Recurrence->new(rrule => 'FREQ=WEEKLY;BYDAY=TU,TH', start => $start);
    my $set  = $rule->with(exdate => [$thanksgiving], rdate => [$moved_to]);

    $set->next($t);  $set->between($a, $b);  $set->first(10);
    $set->rules;  $set->rdates;  $set->exdates;

    my $set = Time::Keeper::Recurrence->parse_ical(<<'ICS');
    DTSTART;TZID=America/New_York:20261020T090000
    RRULE:FREQ=WEEKLY;BYDAY=TU,TH
    EXDATE;TZID=America/New_York:20261126T090000
    ICS
    print $set->ical;

=head1 DESCRIPTION

A real event is seldom one rule: it is a rule plus the dates that were
moved or cancelled, sometimes two rules. A set holds up to sixteen rules,
the dates added (iCalendar's RDATE) and the dates removed (EXDATE), with
one zone, one start and one choice for skipped and doubled clock times
shared by all of them. It walks like a rule does: C<next>, C<previous>,
C<between>, C<first>, C<contains> and C<iterate> give the merge of every
rule's occurrences with the added dates in and the removed ones out, in
order and without duplicates.

A set is made by C<with> on a rule or on another set, or read from
iCalendar text by C<< Time::Keeper::Recurrence->parse_ical >>. Like a rule
it never changes: C<with> gives a new set and leaves the old one as it was.

=head1 MAKING A SET

=head2 with

    my $set = $rule->with(exdate => [$t1, $t2], rdate => $t3, rule => $other);
    my $set = $set->with(exdate => '2026-12-25');

A new set from a rule or a set with dates added (C<rdate>), dates removed
(C<exdate>) or rules added (C<rule>; C<rdates>, C<exdates> and C<rules>
are the same keys). Each value is one item or an array reference of them.

A date added or removed is a Time::Keeper value, which is one occurrence
to the second; or a whole day, as a Time::Keeper::Date or a C<YYYY-MM-DD>
string. A whole day added is its midnight in the set's zone. A whole day
removed takes every occurrence that falls on that day in the set's zone,
as iCalendar's C<EXDATE;VALUE=DATE> does.

A rule added shares the set's zone, and an RRULE its start; one that does
not dies. A cron keeps its own bound. Every rule in a set takes the set's
C<gap> and C<overlap> choice, the first rule's.

A set holds at most sixteen rules and ten thousand dates of each kind.

=head1 WHAT A SET SAYS ABOUT ITSELF

=head2 rules

The rules as Time::Keeper::Recurrence objects, in the order added.

=head2 exrules

The EXRULEs read from iCalendar, if any. Nothing else makes one.

=head2 rdates

The dates added, in order, each a Time::Keeper value or, for a whole day, a
Time::Keeper::Date.

=head2 exdates

The dates removed, likewise.

=head2 start

The set's start as a Time::Keeper value, or undef for a set of crons with
no bound.

=head2 zone

The set's zone by name, as a rule's.

=head2 gap

The choice for a skipped wall time, shared by every rule in the set.

=head2 overlap

The choice for a doubled one, likewise.

=head2 is_finite

True when every rule in the set ends.

=head1 THE WALK

=head2 next

The first occurrence of the set strictly after a moment, or undef.

=head2 previous

The last strictly before, or undef.

=head2 between

A list, the first bound inclusive, the second exclusive.

=head2 first

The first n.

=head2 contains

Whether a moment is an occurrence of the set.

=head2 iterate

A code reference giving the next each call and undef at the end.

All six exactly as the same methods of L<Time::Keeper::Recurrence>, over the set's
occurrences: each rule's, with the added dates in and the removed dates
and the EXRULEs' occurrences out. An instant two rules both give, or a
date added that a rule gives anyway, comes once. A removed date to the
second removes only that instant; a removed whole day removes every
occurrence of that day in the set's zone, whichever rule gave it.

=head1 ICALENDAR

=head2 parse_ical

    my $set = Time::Keeper::Recurrence::Set->parse_ical($text);

The same as L<Time::Keeper::Recurrence/parse_ical>, blessed into the class
it is called on.

=head2 ical

    print $set->ical;
    # DTSTART;TZID=America/New_York:20261020T090000
    # RRULE:FREQ=WEEKLY;BYDAY=TU,TH
    # EXDATE;TZID=America/New_York:20261126T090000

The set as iCalendar content lines, which is also what a set stringifies
to: a DTSTART with the zone as a TZID (none for UTC, which ends in Z, or a
floating start; a fixed offset is written as its own name), one RRULE a
rule, RDATE and EXDATE lines with the timed dates and, apart, the whole
days as C<VALUE=DATE>. Lines end in CRLF and are folded at 75 octets, as
RFC 5545 says. An EXRULE is read but never written: RFC 5545 withdrew it. A
cron is written as the RRULE it is; one that fires on either of two day
fields, or an C<@every>, has no RRULE and dies here.

See C<parse_ical> in L<Time::Keeper::Recurrence> for the reading side.

=head1 SERIALISATION

The frozen form of a set is text: a header line with C<tkrs1>, the gap and
overlap choices, the locale and whether the start is a whole day, then the
iCalendar lines with any EXRULE kept and every cron as an C<X-TKR-CRON>
line (which L</parse_ical> also reads), so a set stores its zone by name
and comes back whole.

=head2 FREEZE

The text, for CBOR::XS, Sereal and JSON::XS with C<allow_tags>.

=head2 THAW

A set from that text.

=head2 STORABLE_freeze

The same text, for Storable: C<freeze>, C<thaw> and C<dclone> work on a set.

=head2 STORABLE_thaw

A set from it, into the object Storable is building.

=head2 TO_JSON

For JSON encoders with C<convert_blessed>: the L</ical> text.

=head1 SEE ALSO

L<Time::Keeper::Recurrence>, L<Time::Keeper>, RFC 5545.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
