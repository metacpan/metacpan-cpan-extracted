package WWW::MetaForge::ArcRaiders::Result::Item;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Item result object

use Moo;
use Types::Standard qw(Str Int Num ArrayRef HashRef Maybe);
use namespace::clean;

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

has slug => (
  is  => 'ro',
  isa => Maybe[Str],
);

has category => (
  is  => 'ro',
  isa => Maybe[Str],
);

has rarity => (
  is  => 'ro',
  isa => Maybe[Str],
);

has description => (
  is  => 'ro',
  isa => Maybe[Str],
);

has stats => (
  is  => 'ro',
  isa => Maybe[HashRef],
);

has weight => (
  is  => 'ro',
  isa => Maybe[Num],
);

has stack_size => (
  is  => 'ro',
  isa => Maybe[Int],
);

has base_value => (
  is  => 'ro',
  isa => Maybe[Int],
);

has crafting_requirements => (
  is      => 'ro',
  isa     => ArrayRef[HashRef],
  default => sub { [] },
);

has sold_by => (
  is      => 'ro',
  isa     => ArrayRef[HashRef],
  default => sub { [] },
);

has used_in => (
  is      => 'ro',
  isa     => ArrayRef,
  default => sub { [] },
);

has compatible_with => (
  is      => 'ro',
  isa     => ArrayRef,
  default => sub { [] },
);

has recycle_yield => (
  is  => 'ro',
  isa => Maybe[HashRef],
);

has last_updated => (
  is  => 'ro',
  isa => Maybe[Str],
);

has _raw => (
  is  => 'ro',
  isa => HashRef,
);

sub from_hashref {
  my ($class, $data) = @_;

  # Handle both documented and actual API field names
  my $stats = $data->{stats} // $data->{stat_block};
  my $weight = $data->{weight} // ($stats ? $stats->{weight} : undef);
  my $stack_size = $data->{stackSize} // ($stats ? $stats->{stackSize} : undef);

  return $class->new(
    id                    => $data->{id},
    name                  => $data->{name},
    slug                  => $data->{slug} // $data->{id},
    category              => $data->{category} // $data->{item_type},
    rarity                => $data->{rarity},
    description           => $data->{description},
    stats                 => $stats,
    weight                => $weight,
    stack_size            => $stack_size,
    base_value            => $data->{baseValue} // $data->{value},
    crafting_requirements => $data->{components} // [],
    sold_by               => $data->{soldBy} // [],
    used_in               => $data->{usedIn} // [],
    compatible_with       => $data->{compatibleWith} // [],
    recycle_yield         => $data->{recycleYield},
    last_updated          => $data->{lastUpdated} // $data->{updated_at},
    _raw                  => $data,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::Result::Item - Item result object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $items = $api->items(search => 'Ferro');
  for my $item (@$items) {
      say $item->name . " (" . $item->rarity . ")";
      say "  Weight: " . $item->weight if $item->weight;
  }

=head1 DESCRIPTION

Represents an item from the ARC Raiders game (weapons, mods, materials, consumables).

=head1 ATTRIBUTES

=head2 id

Item identifier (string slug).

=head2 name

Human-readable item name.

=head2 slug

URL-safe identifier.

=head2 category

Item type (e.g., "Weapon", "Material", "Consumable").

=head2 rarity

Item rarity (e.g., "Common", "Rare", "Legendary").

=head2 description

Item description text.

=head2 stats

HashRef of item statistics (damage, range, etc.).

=head2 weight

Item weight value.

=head2 stack_size

Maximum stack size for stackable items.

=head2 base_value

Base monetary value.

=head2 crafting_requirements

ArrayRef of crafting ingredients: C<[{ item => "Name", quantity => 5 }]>.

=head2 sold_by

ArrayRef of traders that sell this item.

=head2 used_in

ArrayRef of recipes/crafts using this item.

=head2 compatible_with

ArrayRef of compatible items.

=head2 recycle_yield

HashRef of materials from recycling.

=head2 last_updated

ISO timestamp of last data update.

=head1 METHODS

=head2 from_hashref

  my $item = WWW::MetaForge::ArcRaiders::Result::Item->from_hashref(\%data);

Construct from API response. Handles field name mapping.

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
