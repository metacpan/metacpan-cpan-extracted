use strict;
use warnings;

package WebService::TVDB::Banner;
{
  $WebService::TVDB::Banner::VERSION = '1.133200';
}

# ABSTRACT: Represents a Banner

# Assessors
# alphabetically, case insensitive
use Object::Tiny qw(
  BannerPath
  BannerType
  BannerType2
  Colors
  id
  Language
  Rating
  RatingCount
  Season
  SeriesName
  ThumbnailPath
  VignettePath
);

use constant URL => 'http://thetvdb.com/banners/%s';

sub url {
    my ($self) = @_;
    return sprintf( URL, $self->BannerPath );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TVDB::Banner - Represents a Banner

=head1 VERSION

version 1.133200

=head1 ATTRIBUTES

=head2 BannerPath

=head2 BannerType

=head2 BannerType2

=head2 Colors

=head2 id

=head2 Language

=head2 Rating

=head2 RatingCount

=head2 Season

=head2 SeriesName

=head2 ThumbnailPath

=head2 VignettePath

=head1 METHODS

=head2 url

Generates the URL for the banner.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
