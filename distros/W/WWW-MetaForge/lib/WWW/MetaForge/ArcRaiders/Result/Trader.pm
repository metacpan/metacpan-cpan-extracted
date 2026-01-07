package WWW::MetaForge::ArcRaiders::Result::Trader;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Trader result object

use Moo;
use Types::Standard qw(Str Int ArrayRef HashRef Maybe);
use namespace::clean;

has name => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

has description => (
  is  => 'ro',
  isa => Maybe[Str],
);

has location => (
  is  => 'ro',
  isa => Maybe[Str],
);

has inventory => (
  is      => 'ro',
  isa     => ArrayRef[HashRef],
  default => sub { [] },
);

has last_refresh => (
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
    name         => $data->{name},
    description  => $data->{description},
    location     => $data->{location},
    inventory    => $data->{inventory} // [],
    last_refresh => $data->{lastRefresh},
    _raw         => $data,
  );
}

sub find_item {
  my ($self, $item_name) = @_;
  for my $item ($self->inventory->@*) {
    return $item if lc($item->{item} // '') eq lc($item_name);
  }
  return undef;
}

sub has_item {
  my ($self, $item_name) = @_;
  return defined $self->find_item($item_name);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::Result::Trader - Trader result object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $traders = $api->traders;
  for my $trader (@$traders) {
      say $trader->name;
      if (my $item = $trader->find_item('Ferro I')) {
          say "  Sells Ferro I for $item->{price}";
      }
  }

=head1 DESCRIPTION

Represents a trader NPC from the ARC Raiders game.

=head1 ATTRIBUTES

=head2 name

Trader name (e.g., "Apollo", "TianWen").

=head2 description

Trader description text.

=head2 location

Where the trader can be found.

=head2 inventory

ArrayRef of items for sale: C<[{ item => "Name", price => 1000, stock => 5 }]>.

=head2 last_refresh

ISO timestamp of last inventory refresh.

=head1 METHODS

=head2 from_hashref

  my $trader = WWW::MetaForge::ArcRaiders::Result::Trader->from_hashref(\%data);

Construct from API response.

=head2 find_item

  my $info = $trader->find_item('Ferro I');

Search inventory by name (case-insensitive). Returns inventory entry or undef.

=head2 has_item

  if ($trader->has_item('Metal Parts')) { ... }

Returns true if trader sells the named item.

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
