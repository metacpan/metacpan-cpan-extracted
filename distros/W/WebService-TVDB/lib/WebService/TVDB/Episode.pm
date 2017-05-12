use strict;
use warnings;

package WebService::TVDB::Episode;
{
  $WebService::TVDB::Episode::VERSION = '1.133200';
}

# ABSTRACT: Represents an Episode

# Assessors
# alphabetically, case insensitive
use Object::Tiny qw(
  absolute_number
  airsafter_season
  airsbefore_episode
  airsbefore_season
  Combined_episodenumber
  Combined_season
  DVD_chapter
  DVD_discid
  DVD_episodenumber
  DVD_season
  Director
  EpImgFlag
  EpisodeName
  EpisodeNumber
  filename
  FirstAired
  GuestStars
  id
  IMDB_ID
  Language
  lastupdated
  Overview
  ProductionCode
  Rating
  RatingCount
  seasonid
  SeasonNumber
  seriesid
  Writer
);

sub year {
    my ($self) = @_;
    if ( $self->FirstAired && $self->FirstAired =~ /^(\d{4})-\d{2}-\d{2}$/ ) {
        return $1;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TVDB::Episode - Represents an Episode

=head1 VERSION

version 1.133200

=head1 ATTRIBUTES

=head2 absolute_number

=head2 airsafter_season

=head2 airsbefore_episode

=head2 airsbefore_season

=head2 Combined_episodenumber

=head2 Combined_season

=head2 DVD_chapter

=head2 DVD_discid

=head2 DVD_episodenumber

=head2 DVD_season

=head2 Director

=head2 EpImgFlag

=head2 EpisodeName

=head2 EpisodeNumber

=head2 filename

=head2 FirstAired

=head2 GuestStars

=head2 id

=head2 IMDB_ID

=head2 Language

=head2 lastupdated

=head2 Overview

=head2 ProductionCode

=head2 Rating

=head2 RatingCount

=head2 seasonid

=head2 SeasonNumber

=head2 seriesid

=head2 Writer

=head1 METHODS

=head2 year

Parses the FirstAired attribute to get the year it first aired.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
