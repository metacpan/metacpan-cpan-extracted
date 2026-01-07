package WWW::MetaForge::ArcRaiders::Result::MapMarker;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Map marker result object for ARC Raiders

use Moo;
use Types::Standard qw(Str Bool Maybe Int);
use namespace::clean;

extends 'WWW::MetaForge::GameMapData::Result::MapMarker';

# ARC Raiders specific fields

has category => (
  is  => 'ro',
  isa => Maybe[Str],
);

has subcategory => (
  is  => 'ro',
  isa => Maybe[Str],
);

has instanceName => (
  is  => 'ro',
  isa => Maybe[Str],
);

has behindLockedDoor => (
  is     => 'ro',
  isa    => Bool,
  coerce => sub { $_[0] ? 1 : 0 },
);

has eventConditionMask => (
  is  => 'ro',
  isa => Maybe[Int],
);

has lootAreas => (
  is => 'ro',
  # Can be null, string, or array depending on marker type
);

sub from_hashref {
  my ($class, $data) = @_;

  return $class->new(
    # Base class fields
    id             => $data->{id},
    lat            => $data->{lat},
    lng            => $data->{lng},
    zlayers        => $data->{zlayers},
    mapID          => $data->{mapID},
    updated_at     => $data->{updated_at},
    added_by       => $data->{added_by},
    last_edited_by => $data->{last_edited_by},
    _raw           => $data,
    # ARC Raiders specific
    category           => $data->{category},
    subcategory        => $data->{subcategory},
    instanceName       => $data->{instanceName},
    behindLockedDoor   => $data->{behindLockedDoor} // 0,
    eventConditionMask => $data->{eventConditionMask},
    lootAreas          => $data->{lootAreas},
  );
}

# Convenience accessors

sub type {
  my ($self) = @_;
  return undef unless $self->category;
  return $self->subcategory
    ? $self->category . '/' . $self->subcategory
    : $self->category;
}

sub name { shift->instanceName }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::Result::MapMarker - Map marker result object for ARC Raiders

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $markers = $api->map_data(map => 'dam');
  for my $marker (@$markers) {
      say $marker->category . '/' . $marker->subcategory;
      say "  (" . $marker->lng . ", " . $marker->lat . ")";
      say "  Behind locked door" if $marker->behindLockedDoor;
  }

=head1 DESCRIPTION

Represents a map marker from the ARC Raiders game maps.

Extends L<WWW::MetaForge::GameMapData::Result::MapMarker> with
ARC Raiders specific attributes.

=head1 ATTRIBUTES

=head2 category

Marker category (e.g., "arc", "containers", "locations", "events").

=head2 subcategory

Marker subcategory (e.g., "tick", "pop", "base_container", "player_spawn").

=head2 instanceName

Optional instance name for the marker.

=head2 behindLockedDoor

Boolean indicating if marker is behind a locked door.

=head2 eventConditionMask

Event condition bitmask.

=head2 lootAreas

Loot area data (can be null, string, or array).

=head1 METHODS

=head2 type

Returns "category/subcategory" string.

=head2 name

Alias for C<instanceName>.

=head1 INHERITED ATTRIBUTES

See L<WWW::MetaForge::GameMapData::Result::MapMarker> for base attributes
(id, lat, lng, zlayers, mapID, updated_at, added_by, last_edited_by).

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
