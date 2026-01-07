package WWW::ARDB::Result::ArcEnemy;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: ARC Enemy result object for WWW::ARDB

use Moo;
use Types::Standard qw( Str ArrayRef HashRef Maybe );
use namespace::clean;

our $VERSION = '0.001';

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has icon => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has image => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has drop_table => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has related_maps => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has updated_at => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

has _raw => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

sub from_hashref {
    my ($class, $data) = @_;

    return $class->new(
        id           => $data->{id},
        name         => $data->{name},
        icon         => $data->{icon},
        image        => $data->{image},
        drop_table   => $data->{dropTable} // [],
        related_maps => $data->{relatedMaps} // [],
        updated_at   => $data->{updatedAt},
        _raw         => $data,
    );
}

sub icon_url {
    my $self = shift;
    return unless $self->icon;
    return 'https://ardb.app' . $self->icon if $self->icon =~ m{^/};
    return $self->icon;
}

sub image_url {
    my $self = shift;
    return unless $self->image;
    return 'https://ardb.app' . $self->image if $self->image =~ m{^/};
    return $self->image;
}

sub drops {
    my $self = shift;
    return [ map { $_->{name} } @{$self->drop_table} ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::Result::ArcEnemy - ARC Enemy result object for WWW::ARDB

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $enemy = $api->arc_enemy('wasp');

    print $enemy->name;       # "Wasp"
    print $enemy->icon_url;   # Full URL to icon

    for my $drop (@{$enemy->drop_table}) {
        printf "- %s (%s)\n", $drop->{name}, $drop->{rarity};
    }

    # Or just get drop names
    my $drops = $enemy->drops;  # ['Wires', 'Medium Ammo', ...]

=head1 NAME

WWW::ARDB::Result::ArcEnemy - ARC Enemy result object for WWW::ARDB

=head1 ATTRIBUTES

=head2 id

String. Unique identifier.

=head2 name

String. Enemy name.

=head2 icon

String or undef. Path to icon image.

=head2 image

String or undef. Path to full image.

=head2 drop_table

ArrayRef of HashRefs. Items this enemy can drop, each with C<id>, C<name>,
C<rarity>, C<type>, C<foundIn>, C<value>, C<icon> (detail endpoint only).

=head2 related_maps

ArrayRef. Maps where this enemy appears (detail endpoint only).

=head2 updated_at

String or undef. ISO 8601 timestamp of last update.

=head1 METHODS

=head2 from_hashref($data)

Class method. Creates an ArcEnemy object from API response data.

=head2 icon_url

Returns the full URL to the enemy's icon, or undef if no icon.

=head2 image_url

Returns the full URL to the enemy's image, or undef if no image.

=head2 drops

Returns an ArrayRef of drop item names.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-ardb>

  git clone https://github.com/Getty/p5-www-ardb.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
