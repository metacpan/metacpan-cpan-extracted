use 5.008001;
use strict;
use warnings;

package Time::OlsonTZ::Clustered;
# ABSTRACT: Olson time zone clusters based on similar offset and DST changes
our $VERSION = '0.002'; # VERSION

use Sub::Exporter -setup => {
    exports => [
        qw/find_cluster find_primary is_primary primary_zones timezone_clusters country_codes country_name/
    ]
};

use File::ShareDir::Tarball qw/dist_file/;
use Path::Class;
use Sereal::Encoder qw/encode_sereal/;
use Sereal::Decoder qw/decode_sereal/;

{
    my $clusters;
    my $reverse;

    sub _clusters {
        return $clusters if defined $clusters;
        my $file = dist_file( 'Time-OlsonTZ-Clustered', 'cluster.srl' )
          or die "Can't find cluster.srl in distribution share data";
        $clusters = decode_sereal( scalar file($file)->slurp );
    }

    sub _get_country {
        my ($code) = shift;
        my $cluster = _clusters()->{ uc $code };
        return $cluster ? decode_sereal( encode_sereal($cluster) ) : undef;
    }

    sub _reverse_map {
        return $reverse if defined $reverse;
        my $file = dist_file( 'Time-OlsonTZ-Clustered', 'reverse.srl' )
          or die "Can't find reverse.srl in distribution share data";
        $reverse = decode_sereal( scalar file($file)->slurp );
    }
}

#--------------------------------------------------------------------------#
# high level functions
#--------------------------------------------------------------------------#


sub primary_zones {
    my ($code) = @_;

    my $country = _get_country($code)
      or return [];
    my $clusters     = $country->{clusters};
    my $order        = $country->{cluster_order};
    my $country_name = $country->{olson_name};

    my @zones;
    for my $c (@$order) {
        my $description = $clusters->{$c}{description};
        my $first       = $clusters->{$c}{zones}[0];
        my %primary     = (
            description => $description || $country_name,
            offset => $first->{offset},
            timezone_name => $first->{timezone_name},
        );
        push @zones, \%primary;
    }
    return \@zones;
}


sub find_primary {
    my ($zone) = @_;
    my $cluster = find_cluster($zone)
      or return;
    return $cluster->{zones}[0]{timezone_name};
}


sub is_primary {
    my ($zone) = @_;
    my $primary = find_primary($zone) || '';
    return $primary eq $zone;
}

#--------------------------------------------------------------------------#
# lower level functions
#--------------------------------------------------------------------------#


sub country_codes {
    my @list = sort keys %{ _clusters() };
    return @list;
}


sub country_name {
    my ($code) = @_;
    my $country = _get_country($code)
      or return '';
    return $country->{olson_name} || '';
}


sub timezone_clusters {
    my ($code) = @_;
    my $country = _get_country($code)
      or return [];
    my $clusters = $country->{clusters};
    my $order    = $country->{cluster_order};

    return [ map { $clusters->{$_} } @$order ];
}


sub find_cluster {
    my ($zone) = @_;
    my $reverse = _reverse_map()->{$zone}
      or return;
    my ( $code, $digest ) = @$reverse;
    my $country = _get_country($code)
      or return;
    return $country->{clusters}{$digest};
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=head1 NAME

Time::OlsonTZ::Clustered - Olson time zone clusters based on similar offset and DST changes

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Time::OlsonTZ::Clustered ':all';

    say $_->timezone_name for @{ primary_zones('US') };
    # Pacific/Honolulu
    # America/Adak
    # America/Anchorage
    # America/Los_Angeles
    # America/Metlakatla
    # America/Denver
    # America/Phoenix
    # America/Chicago
    # America/New_York

    say find_primary("America/Indiana/Indianapolis");
    # America/New_York

=head1 DESCRIPTION

There are over 400 Olson time zone names (e.g. "America/New_York")
describing current and historical offset and daylight-savings behavior.  While
this is essential for accurate calculations involving times in the
past, it is an overwhelming list to present as part of a user experience
current behavior is relevant. (E.g. "Choose your time zone")

For example, China has had only one official time (UTC+8) since 1949, but there
are five Olson time zones corresponding to historical districts:

    Asia/Shanghai
    Asia/Chongqing
    Asia/Kashgar
    Asia/Urumqi
    Asia/Harbin

When presenting a list of time zone choices, there are many situations in which
it is sufficient to present "Asia/Shanghai" for China.  Likewise, the United
States has consolidated some of its historically fragmented time zone
observance.  Instead of asking someone if they are in
"America/Indiana/Indianapolis", it is sufficient to ask them to pick
"America/New_York" (a.k.a. "US Eastern Time").

This module provides a pre-calculated clustering the 400+ Olson time zones by
country and by time observance behavior, allowing a consolidated list of
"primary zones" to be offered for each country.

The clustering was developed using the following heuristics and modifications:

=over 4

=item *

For each country, cluster time zones by observance behavior

=item *

Zones cluster together if they have the same UTC offset at local noon for the next 365 days

=item *

If a cluster contains multiple zones, the author selected a primary zone using research and judgment

=item *

Multiple-zone clusters were given a descriptive name

=back

Cluster descriptions were based on either the primary zone description (the
Olson 'region_description' field) -- e.g. "McMurdo Station, Ross Island" for
the cluster containing "Antartica/McMurdo" and "Antarctica/South_Pole" -- or else
a subjectively-determined, broadly descriptive term common across the zones
-- e.g. "Central time" for various US zones with a UTC-6 offset.

When a country had a single cluster, the cluster description was left blank,
similar to how the Olson database leaves the time zone description blank.
(N.B. the C<primary_zones()> function returns the country name when there is no
cluster description.)

Some additional modifications were made to account for errors in the Olson time
zone files.

Cluster names were made on a best-efforts basis by the author.  If you have
suggested improvements, please file a bug report with your ideas.

The clustering will be updated over time as the Olson time zone database changes.

=head1 FUNCTIONS

=head2 primary_zones

    my $zones = primary_zones('US');

Takes a country code and returns a reference to an array of hash references.
Each element in the array represents one timezone cluster in the country,
sorted by UTC offset.  The hash reference contains the following keys:

=over 4

=item *

description: Description of the zone or the Olson country name if there is only one cluster

=item *

offset: UTC offset, expressed in hours ('+5', '-2')

=item *

timezone_name: the primary Olson zone name for the cluster ('America/Chicago')

=back

For example, here are some of the items returned from C<primary_zones('AQ')>:

    [
        {
            'description'   => 'Palmer Station, Anvers Island',
            'offset'        => -4,
            'timezone_name' => 'Antarctica/Palmer'
        },
        {
            'description'   => 'Rothera Station, Adelaide Island',
            'offset'        => -3,
            'timezone_name' => 'Antarctica/Rothera'
        },
        ...
    ]

The description may be the Olson description of the primary zone or it may be a
custom alternative that the author feels best describes the cluster.

Offsets given are the smallest offset observed during the year.  This should correspond
to the non-daylight savings time offset in zones that observe daylight savings time
for part of the year.

The primary zone is the best guess at the most common or recognizable Olson
name in the cluster; see the L</DESCRIPTION> section for details.

If an invalid country code is given, the function returns an empty array reference.

=head2 find_primary

    my $primary = find_primary("America/Indiana/Indianapolis");
    # returns "America/New_York"

Given an Olson time zone name, returns the primary zone name for the cluster
containing the zone.  Returns undef or the empty list if the zone is
not recognized.

=head2 is_primary

    if ( is_primary("America/Chicago") ) { ... }

A boolean function to check if a time zone is primary for its cluster.

=head2 country_codes

    for my $cc ( country_codes() ) {
        ...
    }

Returns a sorted list of known country codes in the cluster
database.

=head2 country_name

    my $name = country_name("US");

Returns the Olson country name (or an empty string)
for a given country code.  This duplicates information
available elsewhere and is provided here for convenience.

=head2 timezone_clusters

    for my $cluster ( @{ timezone_clusters('US') } ) {
        ...
    }

Given a country code, returns an array reference of raw cluster data for the
country (or an empty array reference if the country code is not found).

Each cluster is a hash reference with C<description> and C<zones>. The C<zones>
entry is an array reference of time zone hashes similar to that returned by
C<primary_zones>, but with C<olson_description> containing the the original
Olson description rather than C<description> for the cluster.  Note that for
single-cluster countries, the cluster description will be blank.

For example, C<timezone_clusters("US")> will return a data structure like this:

    [
        {
            'description' => 'Hawaii',
            'zones'       => [
                {
                    'offset'            => -10,
                    'olson_description' => 'Hawaii',
                    'timezone_name'     => 'Pacific/Honolulu'
                }
            ]
        },
        {
            'description' => 'Aleutian Islands',
            'zones'       => [
                {
                    'offset'            => -10,
                    'olson_description' => 'Aleutian Islands',
                    'timezone_name'     => 'America/Adak'
                }
            ]
        },
        {
            'description' => 'Alaska Time',
            'zones'       => [
                {
                    'offset'            => '-9',
                    'olson_description' => 'Alaska Time',
                    'timezone_name'     => 'America/Anchorage'
                },
                {
                    'offset'            => -9,
                    'olson_description' => 'Alaska Time - west Alaska',
                    'timezone_name'     => 'America/Nome'
                },
                {
                    'offset'            => '-9',
                    'olson_description' => 'Alaska Time - Alaska panhandle',
                    'timezone_name'     => 'America/Juneau'
                },
                {
                    'offset'            => '-9',
                    'olson_description' => 'Alaska Time - Alaska panhandle neck',
                    'timezone_name'     => 'America/Yakutat'
                },
                {
                    'offset'            => '-9',
                    'olson_description' => 'Alaska Time - southeast Alaska panhandle',
                    'timezone_name'     => 'America/Sitka'
                },
            ]
        },
        ...
    ]

=head2 find_cluster

    my $cluster = find_cluster("America/Indiana/Indianapolis");

Given an Olson time zone name, returns the cluster data structure
containing the time zone.  It returns undef or the empty list
if the time zone name is not recognized.

=for Pod::Coverage method_names_here

=head1 USAGE

All functions are optionally exported using L<Sub::Exporter>.

=head1 SEE ALSO

=over 4

=item *

L<DateTime::TimeZone::Olson>

=back

=head1 ACKNOWLEDGMENTS

The author would like to thank the following people for their help:

=over 4

=item *

Andrew Main (ZEFRAM) for his time zone modules and advice on zone clustering heuristics.

=item *

Breno G. de Oliveira (GARU) for his patient explanations and advice regarding Brazilian time zones.

=back

Any errors are solely those of the author (or the upstream Olson database).

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/time-olsontz-clustered/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/time-olsontz-clustered>

  git clone git://github.com/dagolden/time-olsontz-clustered.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
