package WWW::MetaForge::ArcRaiders::CLI::Cmd::Items;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List items from the ARC Raiders API

use Moo;
use MooX::Cmd;
use MooX::Options;
use JSON::MaybeXS;

option search => (
  is      => 'ro',
  format  => 's',
  short   => 's',
  doc     => 'Search term to filter items by name',
);

option limit => (
  is      => 'ro',
  format  => 'i',
  short   => 'l',
  doc     => 'Maximum number of results to display',
);

option category => (
  is      => 'ro',
  format  => 's',
  short   => 'c',
  doc     => 'Filter by item category',
);

option rarity => (
  is      => 'ro',
  format  => 's',
  short   => 'r',
  doc     => 'Filter by item rarity',
);

option page => (
  is      => 'ro',
  format  => 'i',
  short   => 'p',
  doc     => 'Page number for pagination',
);

option all => (
  is      => 'ro',
  short   => 'a',
  doc     => 'Fetch all pages',
);

sub execute {
  my ($self, $args, $chain) = @_;
  my $app = $chain->[0];

  my %params;
  $params{search} = $self->search if $self->search;
  $params{page} = $self->page if $self->page;
  $params{limit} = $self->limit if $self->limit;

  my ($items, $pagination);

  if ($self->all) {
    $items = $app->api->items_all(%params);
  } else {
    my $result = $app->api->items_paginated(%params);
    $items = $result->{data};
    $pagination = $result->{pagination};
  }

  # Apply local filters
  if ($self->category) {
    my $cat = lc($self->category);
    $items = [ grep { $_->category && lc($_->category) =~ /\Q$cat\E/ } @$items ];
  }
  if ($self->rarity) {
    my $rar = lc($self->rarity);
    $items = [ grep { $_->rarity && lc($_->rarity) eq $rar } @$items ];
  }

  if ($app->json) {
    print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode(
      [ map { $_->_raw } @$items ]
    );
    return;
  }

  if (!@$items) {
    print "No items found.\n";
    return;
  }

  for my $item (@$items) {
    my $name = $item->name // $item->id // 'Unknown';
    my $cat  = $item->category // '-';
    my $rar  = $item->rarity // '-';
    my $id   = $item->slug // $item->id // '-';
    printf "%-40s  %-18s  %-10s  [%s]\n", $name, $cat, $rar, $id;
  }

  my $shown = scalar(@$items);
  if ($pagination && !$self->all) {
    my $total = $pagination->{total} // '?';
    my $page_num = $pagination->{page} // 1;
    my $total_pages = $pagination->{totalPages} // '?';
    printf "\n%d item(s) shown (page %d/%s, %s total). Use --all to fetch all pages.\n",
      $shown, $page_num, $total_pages, $total;
  } else {
    printf "\n%d item(s) found.\n", $shown;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::CLI::Cmd::Items - List items from the ARC Raiders API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  arcraiders items
  arcraiders items --search Ferro
  arcraiders items --category Weapon --rarity Rare

=head1 DESCRIPTION

Lists items from the ARC Raiders game database.

=head1 OPTIONS

=over 4

=item --search, -s

Search term to filter items by name.

=item --limit, -l

Maximum number of results to display.

=item --category, -c

Filter by item category.

=item --rarity, -r

Filter by item rarity.

=item --page, -p

Page number for pagination.

=item --all, -a

Fetch all pages.

=back

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
