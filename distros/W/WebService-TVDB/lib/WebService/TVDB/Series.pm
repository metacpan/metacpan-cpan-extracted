use strict;
use warnings;

package WebService::TVDB::Series;
{
  $WebService::TVDB::Series::VERSION = '1.133200';
}

# ABSTRACT: Represents a TV Series

use WebService::TVDB::Actor;
use WebService::TVDB::Banner;
use WebService::TVDB::Episode;
use WebService::TVDB::Util qw(pipes_to_array);

use Carp qw(carp);
use File::Basename qw(dirname);
use File::Path qw(mkpath);
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use LWP::Simple ();
use XML::Simple qw(:strict);

# Assessors
# alphabetically, case insensitive
# First section from http://thetvdb.com/api/GetSeries.php?seriesname=...
# Second section from <langauge.xml>
# Third section are WebService::TVDB:: objects
# Forth section are API values
use Object::Tiny qw(
  banner
  FirstAired
  id
  IMDB_ID
  language
  Overview
  seriesid
  SeriesName
  zap2it_id

  added
  addedBy
  Actors
  Airs_DayOfWeek
  Airs_Time
  ContentRating
  fanart
  Genre
  Language
  lastupdated
  Network
  NetworkID
  poster
  Rating
  RatingCount
  Runtime
  SeriesID
  Status

  actors
  banners
  episodes

  _api_key
  _api_language
  _max_retries
);

# the url for full series data
use constant URL => 'http://thetvdb.com/api/%s/series/%s/all/%s.zip';

# the local path for full series data
use constant CACHE_PATH => '%s/.tvdbcache/series/%s/all/%s.zip';

# xml files in the zip
use constant ACTORS_XML_FILE  => 'actors.xml';
use constant BANNERS_XML_FILE => 'banners.xml';

sub fetch {
    my ($self) = @_;

    my $url        = $self->_url;
    my $cache_path = $self->_cache_path;
    $cache_path =~ /\A(.*)\z/s or die;
    $cache_path = $1;    # ensure its untainted
    my $dir = dirname($cache_path);
    -e $dir or mkpath($dir) or die 'could not create ' . $dir;

    my $agent = $LWP::Simple::ua->agent;
    $LWP::Simple::ua->agent("WebService::TVDB/$WebService::TVDB::VERSION");

    # get the zip
    my $res = LWP::Simple::mirror( $url, $cache_path );
    my $retries = 0;
    until (  $res == LWP::Simple::RC_NOT_MODIFIED
          || LWP::Simple::is_success($res)
          || $retries == $self->_max_retries )
    {
        carp "failed to get URL $url: $res - retrying";

        # TODO configurable wait time
        sleep 1;
        $res = LWP::Simple::mirror( $url, $cache_path );

        $retries++;
    }
    $LWP::Simple::ua->agent($agent);
    if ( $retries == $self->_max_retries ) {
        die "failed to get URL $url after $retries retries. Aborting.";
    }
    my $zip = Archive::Zip->new();
    unless ( $zip->read($cache_path) == AZ_OK ) {
        die 'could not read zip at ' . $cache_path;
    }

    # parse the xml files
    my $status;
    my $xml;
    my $parsed_xml;

    my $series_xml_file = $self->language . '.xml';
    ( $xml, $status ) = $zip->contents($series_xml_file);
    unless ( $status == AZ_OK ) {
        die 'could not read ' . $series_xml_file;
    }
    $parsed_xml = XML::Simple::XMLin(
        $xml,
        ForceArray    => [ 'Data', 'Episode' ],
        KeyAttr       => 'Data',
        SuppressEmpty => 1
    );
    $self->_parse_series_data($parsed_xml);

    ( $xml, $status ) = $zip->contents(ACTORS_XML_FILE);
    unless ( $status == AZ_OK ) {
        die 'could not read ' . ACTORS_XML_FILE;
    }
    $parsed_xml = XML::Simple::XMLin(
        $xml,
        ForceArray    => ['Actor'],
        KeyAttr       => 'Actor',
        SuppressEmpty => 1
    );
    $self->_parse_actors($parsed_xml);

    ( $xml, $status ) = $zip->contents(BANNERS_XML_FILE);
    unless ( $status == AZ_OK ) {
        die 'could not read ' . BANNERS_XML_FILE;
    }
    $parsed_xml = XML::Simple::XMLin(
        $xml,
        ForceArray    => ['Banner'],
        KeyAttr       => 'Banner',
        SuppressEmpty => 1
    );
    $self->_parse_banners($parsed_xml);
}

sub get_episode {
    my ( $self, $season_number, $episode_number ) = @_;

    for my $episode ( @{ $self->episodes } ) {
        if ( $episode->SeasonNumber eq $season_number ) {
            if ( $episode->EpisodeNumber eq $episode_number ) {
                return $episode;
            }
        }

    }
}

# generates the url for full series data
sub _url {
    my ($self) = @_;
    return sprintf( URL,
        $self->_api_key, $self->seriesid,
        $self->_api_language->{abbreviation} );
}

# generates the local path for full series data
# TODO configurable path
sub _cache_path {
    my ($self) = @_;
    require File::HomeDir;
    return sprintf( CACHE_PATH,
        File::HomeDir->my_home, $self->seriesid,
        $self->_api_language->{abbreviation} );
}

# parse <language>.xml
sub _parse_series_data {
    my ( $self, $xml ) = @_;

    # populate extra Series data
    while ( my ( $key, $value ) = each( %{ $xml->{Series} } ) ) {
        if ( $key eq 'Genre' || $key eq 'Actors' ) {
            $self->{$key} = pipes_to_array($value);
        }
        else {
            $self->{$key} = $value;
        }
    }

    # populate Episodes, if they exist
    my @episodes;
    if ( $xml->{Episode} ) {
        for ( @{ $xml->{Episode} } ) {
            push @episodes, WebService::TVDB::Episode->new( %{$_} );

        }
    }
    $self->{episodes} = \@episodes;
    return $self->{episodes};
}

# parse actors.xml
sub _parse_actors {
    my ( $self, $xml ) = @_;

    my @actors;
    for ( @{ $xml->{Actor} } ) {
        push @actors, WebService::TVDB::Actor->new( %{$_} );

    }
    $self->{actors} = \@actors;
    return $self->{actors};
}

# parse banners.xml
sub _parse_banners {
    my ( $self, $xml ) = @_;

    my @banners;
    for ( @{ $xml->{Banner} } ) {
        push @banners, WebService::TVDB::Banner->new( %{$_} );

    }
    $self->{banners} = \@banners;
    return $self->{banners};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TVDB::Series - Represents a TV Series

=head1 VERSION

version 1.133200

=head1 ATTRIBUTES

=head2 banner

=head2 FirstAired

=head2 id

=head2 IMDB_ID

=head2 language

=head2 Overview

=head2 seriesid

=head2 SeriesName

=head2 zap2it_id

=head2 added

Populated after fetch

=head2 addedBy

Populated after fetch

=head2 Actors

Populated after fetch

=head2 Airs_DayOfWeek

Populated after fetch

=head2 Airs_Time

Populated after fetch

=head2 ContentRating

Populated after fetch

=head2 fanart

Populated after fetch

=head2 Genre

Populated after fetch

=head2 Language

Populated after fetch

=head2 lastupdated

Populated after fetch

=head2 Network

Populated after fetch

=head2 NetworkID

Populated after fetch

=head2 poster

Populated after fetch

=head2 Rating

Populated after fetch

=head2 RatingCount

Populated after fetch

=head2 Runtime

Populated after fetch

=head2 SeriesID

Populated after fetch

=head2 Status

Populated after fetch

=head2 actors

An array of L<WebService::TVDB::Actor> objects. Populated after fetch.

=head2 banners

An array of L<WebService::TVDB::Banner> objects. Populated after fetch.

=head2 episodes

An array of L<WebService::TVDB::Episode> objects. Populated after fetch.

=head1 METHODS

=head2 fetch

Fecthes the full data from the TVDB, inluding all the episodes.

=head2 get_episode ( $season_number, $episode_number )

Gets a parcular episode. Returns a L<WebService::TVDB::Episode> object.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
