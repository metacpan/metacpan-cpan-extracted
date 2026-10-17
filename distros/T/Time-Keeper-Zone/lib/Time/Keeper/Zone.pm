package Time::Keeper::Zone;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Time::Keeper::Zone', $VERSION);

1;

__END__

=head1 NAME

Time::Keeper::Zone - the time zones of the IANA database, compiled in

=head1 VERSION

Version 0.01

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
system's time zone setting. When none of them names a zone it is
C<Etc/UTC>. Only names are read: the system's own zone files never are.

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
