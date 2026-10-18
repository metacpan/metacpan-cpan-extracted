package Time::Keeper::Zone;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Time::Keeper::Zone', $VERSION);

1;

__END__

=head1 NAME

Time::Keeper::Zone - the time zones of the IANA database, compiled in

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Time::Keeper::Zone;

    my @zones = Time::Keeper::Zone->names;
    my %links = Time::Keeper::Zone->links;

    Time::Keeper::Zone->is_valid('europe/london');        # true
    Time::Keeper::Zone->name('europe/london');            # Europe/London
    Time::Keeper::Zone->canonical_name('US/Eastern');     # America/New_York
    Time::Keeper::Zone->local_name;                       # this machine's zone
    Time::Keeper::Zone->tzdata_version;                   # 2026e

    my %countries = Time::Keeper::Zone->countries;
    my @zones_gb  = Time::Keeper::Zone->zones_for_country('GB');
    Time::Keeper::Zone->windows_zone('GMT Standard Time');  # Europe/London
    Time::Keeper::Zone->windows_name('Europe/London');      # GMT Standard Time
    Time::Keeper::Zone->country_of('Europe/London');        # GB

    my @changes = Time::Keeper::Zone->transitions('Europe/London', $from, $to);
    my $next    = Time::Keeper::Zone->next_transition('Europe/London', time);
    my ($offset, $is_dst, $abbr) = Time::Keeper::Zone->offset_at('Europe/London', time);
    Time::Keeper::Zone->standard_offset_at('Europe/London', time);   # 0
    Time::Keeper::Zone->has_dst('Asia/Tokyo', 2026);                 # false

=head1 DESCRIPTION

Time::Keeper::Zone holds the time zones that L<Time::Keeper> uses. It is a
dist of its own so that a new release of the IANA time zone database is a
new release of this dist alone, and Time::Keeper itself does not change.

The zone data is compiled into the module. The system's own zone files are
never read, so every machine gives the same answer for the same version of
this dist.

Time::Keeper loads this module the first time a named zone is asked for. A
program that works only in UTC or in fixed offsets never loads it.

A zone here is a name, not an object. Times in a zone are asked of
L<Time::Keeper>; this module answers questions about the zones themselves.
Every method is a class method.

Names are matched without regard to case: C<europe/london> is
C<Europe/London>. A link is an older or alternative name for a zone, such
as C<US/Eastern> for C<America/New_York>; it follows that zone's rules
exactly, and keeps its own name.

=head1 THE TIME ZONE DATABASE

This release carries the IANA time zone database's release 2026e, which
L</tzdata_version> also gives. IANA publishes several releases a year,
whenever a country changes its clocks, often at short notice; a new one is a
new release of this dist, and of this dist alone. Upgrading it is all a
program needs to know of a change.

The system's zone files are never read. They are a different release on
every machine, sometimes years old, sometimes missing (a minimal container,
Windows), and reading them is file I/O on the first use of every zone.
Compiled in, the data is the same on every machine for the same version of
this dist, it is checked by this dist's tests, and finding a zone costs
nothing.

The database's own build is compiled, as C<zic> builds it by default: the
history of zones before 1970 that IANA keeps apart, in its F<backzone>
file, is not included, as L<DateTime::TimeZone> leaves it out too.

=head1 METHODS

=head2 names

Every zone's name, in order. Links are not included: see L</links>.

=head2 links

Every link, as a list of pairs: the link's name, then the name of the zone
it follows. Assign it to a hash.

=head2 is_valid($name)

True if C<$name> is a zone or a link, in any case.

=head2 name($name)

C<$name> as the database spells it, or undef if it is not a zone or link.
A link gives back its own name.

=head2 canonical_name($name)

The zone C<$name> follows: the zone itself, or for a link the zone it
leads to. Undef if it is neither.

=head2 local_name

The name of this machine's zone. It comes from the C<TZ> environment
variable if that names a zone (C<:> before the name and a path ending in
C<zoneinfo/I<Area/City>> are both understood, and an empty C<TZ> means
UTC), then from the name F</etc/localtime> links to, then
F</etc/timezone>, then F</etc/sysconfig/clock>, and on Windows from the
system's time zone key name mapped as C<windows_zone> maps it. When none
of them names a zone it is C<Etc/UTC>. Only names are read: the system's
own zone files never are.

=head2 tzdata_version

The release of the IANA time zone database compiled in, such as C<2026e>.

=head2 countries

Every country with a zone, as pairs of its ISO 3166 code and its name.

=head2 zones_for_country($code)

The zones a country uses, from the database's F<zone.tab>, given its
two-letter code in any case. A country whose clocks follow another's still
has its own zone here: Norway's is C<Europe/Oslo>. An empty list for a
code that is not there.

=head2 windows_zone($windows_name)

The zone a Windows time zone name means, such as C<Europe/London> for
C<GMT Standard Time>, from CLDR's table. Undef for a name it does not
know.

=head2 windows_name($name)

The Windows time zone name of the zone C<$name> follows, such as
C<GMT Standard Time> for C<Europe/London>: the reverse of
C<windows_zone>. Undef for a zone Windows has no name of its own for,
such as C<America/Detroit>, and for a name that is not a zone or link.

=head2 country_of($name)

The ISO 3166 code of the country C<$name> belongs to, such as C<GB> for
C<Europe/London>: the reverse of C<zones_for_country>. A link the
database's F<zone.tab> lists has its own country (C<Europe/Oslo> is
C<NO>); any other link has its zone's (C<US/Eastern> is C<US>). Undef for
a zone of no country, such as C<Etc/UTC>, and for a name that is not a
zone or link.

=head1 TRANSITIONS

A transition is an instant at which a zone's offset, its DST flag or its
abbreviation changes. A change of abbreviation alone is one, and is
listed: the offset before and after it are then the same.

The methods below take times as epoch seconds (seconds since
1970-01-01T00:00:00 UTC, leap seconds not counted), and a fraction counts
as the second it falls in. They croak for a name that is not a zone or a
link. Past a zone's last transition in the database, its rule for the
future (a POSIX TZ string) gives every later transition, for any year.

A zone with a fixed offset, such as C<Etc/GMT+5>, has no transitions.

=head2 transitions($name, $from, $to)

Each transition from C<$from> to C<$to>, both included, as a list of array
references:

    [ $epoch, $offset_before, $offset_after, $abbreviation_after, $is_dst_after ]

Offsets are seconds east of UTC, and C<$is_dst_after> is 1 or 0. Croaks if
C<$to> is before C<$from> or more than 1,000 years (of 365.25 days) after it.

    for my $t (Time::Keeper::Zone->transitions('Europe/London', $from, $to)) {
        my ($at, $before, $after, $abbr, $is_dst) = @$t;
        ...
    }

=head2 next_transition($name, $epoch)

The first transition after C<$epoch>, as epoch seconds, or undef if the
zone never changes again.

=head2 previous_transition($name, $epoch)

The last transition before C<$epoch>, or undef if there is none.

=head2 offset_at($name, $epoch)

In list context the zone's offset in seconds east of UTC at C<$epoch>, 1
or 0 for whether it is daylight time, and the abbreviation in use:

    my ($offset, $is_dst, $abbr) = Time::Keeper::Zone->offset_at('Europe/London', $epoch);

In scalar context the offset alone.

=head2 standard_offset_at($name, $epoch)

The offset of the zone's standard time at C<$epoch>, in seconds east of
UTC: during summer time, the offset it is an hour ahead of.

This is what the database's types say is standard, which is not always
what the clocks are called. Europe/Dublin's standard time is Irish
Standard Time, +01:00, all year: the database has GMT in winter as its
daylight time, an hour behind. A zone in daylight time with no standard
time since gives the standard offset it last had.

=head2 has_dst($name, $year)

True if the DST flag changes during C<$year>, as the zone's own clocks
count the year: London in 2026 does, Tokyo and Kolkata do not.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-keeper-zone at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Keeper-Zone>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
