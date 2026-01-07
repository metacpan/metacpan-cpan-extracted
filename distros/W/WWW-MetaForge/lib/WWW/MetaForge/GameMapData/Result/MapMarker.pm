package WWW::MetaForge::GameMapData::Result::MapMarker;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Base map marker result object for MetaForge Game Map Data API

use Moo;
use Types::Standard qw(Str Num Int HashRef Maybe);
use namespace::clean;

# Generic fields common to all game map data

has id => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

has lat => (
  is       => 'ro',
  isa      => Num,
  required => 1,
);

has lng => (
  is       => 'ro',
  isa      => Num,
  required => 1,
);

has zlayers => (
  is  => 'ro',
  isa => Maybe[Int],
);

has mapID => (
  is  => 'ro',
  isa => Maybe[Str],
);

has updated_at => (
  is  => 'ro',
  isa => Maybe[Str],
);

has added_by => (
  is  => 'ro',
  isa => Maybe[Str],
);

has last_edited_by => (
  is  => 'ro',
  isa => Maybe[Str],
);

has _raw => (
  is  => 'ro',
  isa => HashRef,
);

sub from_hashref {
  my ($class, $data) = @_;

  return $class->new(
    id             => $data->{id},
    lat            => $data->{lat},
    lng            => $data->{lng},
    zlayers        => $data->{zlayers},
    mapID          => $data->{mapID},
    updated_at     => $data->{updated_at},
    added_by       => $data->{added_by},
    last_edited_by => $data->{last_edited_by},
    _raw           => $data,
  );
}

# Convenience accessors

sub x { shift->lng }
sub y { shift->lat }
sub z { shift->zlayers }

# Subclasses should override to provide marker type
sub type { undef }
sub name { undef }

sub coordinates {
  my ($self) = @_;
  return {
    x => $self->lng,
    y => $self->lat,
    defined $self->zlayers ? (z => $self->zlayers) : (),
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::GameMapData::Result::MapMarker - Base map marker result object for MetaForge Game Map Data API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $markers = $api->map_data(map => 'dam');
  for my $marker (@$markers) {
      say "Marker at " . $marker->lng . ", " . $marker->lat;
  }

=head1 DESCRIPTION

Base class for map marker objects from the MetaForge Game Map Data API.
Contains only generic fields common to all games.

Game-specific distributions should subclass this to add game-specific
attributes (like category, subcategory for ARC Raiders).

=head1 ATTRIBUTES

=head2 id

Unique marker identifier (UUID).

=head2 lat

Latitude (Y coordinate) on the map.

=head2 lng

Longitude (X coordinate) on the map.

=head2 zlayers

Z-layer value for elevation/floor.

=head2 mapID

Map identifier (e.g., "dam", "spaceport").

=head2 updated_at

ISO timestamp of last update.

=head2 added_by

Username who added this marker.

=head2 last_edited_by

Username who last edited this marker.

=head1 METHODS

=head2 from_hashref

  my $marker = WWW::MetaForge::GameMapData::Result::MapMarker->from_hashref(\%data);

Construct from API response hash. Subclasses should override this to
handle game-specific fields.

=head2 x

Alias for C<lng>.

=head2 y

Alias for C<lat>.

=head2 z

Alias for C<zlayers>.

=head2 coordinates

  my $coords = $marker->coordinates;
  # { x => 123.5, y => 78.1 }

Returns HashRef of coordinates.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-metaforge>

  git clone https://github.com/Getty/p5-www-metaforge.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
