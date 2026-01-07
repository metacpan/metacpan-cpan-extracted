package WWW::MetaForge::ArcRaiders::Result::Arc;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Arc (mission/event) result object

use Moo;
use Types::Standard qw(Str Int ArrayRef HashRef Maybe);
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

has type => (
  is  => 'ro',
  isa => Maybe[Str],
);

has description => (
  is  => 'ro',
  isa => Maybe[Str],
);

has maps => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] },
);

has duration => (
  is  => 'ro',
  isa => Maybe[Int],
);

has cooldown => (
  is  => 'ro',
  isa => Maybe[Int],
);

has loot => (
  is      => 'ro',
  isa     => ArrayRef[HashRef],
  default => sub { [] },
);

has xp_reward => (
  is  => 'ro',
  isa => Maybe[Int],
);

has coin_reward => (
  is  => 'ro',
  isa => Maybe[Int],
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

  my $maps = $data->{maps} // ($data->{map} ? [$data->{map}] : []);

  return $class->new(
    id           => $data->{id},
    name         => $data->{name},
    type         => $data->{type},
    description  => $data->{description},
    maps         => $maps,
    duration     => $data->{duration},
    cooldown     => $data->{cooldown} // $data->{frequency},
    loot         => $data->{loot} // [],
    xp_reward    => $data->{xpReward},
    coin_reward  => $data->{coinReward},
    last_updated => $data->{lastUpdated},
    _raw         => $data,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::Result::Arc - Arc (mission/event) result object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $arcs = $api->arcs(includeLoot => 'true');
  for my $arc (@$arcs) {
      say $arc->name . " on " . join(", ", $arc->maps->@*);
  }

=head1 DESCRIPTION

Represents an ARC (mission/event) from the ARC Raiders game.

=head1 ATTRIBUTES

=head2 id

Arc identifier.

=head2 name

Arc name.

=head2 type

Arc type (e.g., "MajorEvent", "MinorEvent").

=head2 description

Arc description text.

=head2 maps

ArrayRef of map names where this arc occurs.

=head2 duration

Duration in seconds.

=head2 cooldown

Cooldown between occurrences in seconds.

=head2 loot

ArrayRef of loot drops: C<[{ item => "Name", chance => 0.15 }]>.

=head2 xp_reward

Experience points reward.

=head2 coin_reward

Coin reward.

=head2 last_updated

ISO timestamp of last data update.

=head1 METHODS

=head2 from_hashref

  my $arc = WWW::MetaForge::ArcRaiders::Result::Arc->from_hashref(\%data);

Construct from API response. Handles both C<map> and C<maps> fields.

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
