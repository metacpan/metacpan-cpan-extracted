package WWW::MetaForge::ArcRaiders::CLI::Cmd::Item;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Show details for a single item

use Moo;
use MooX::Cmd;
use MooX::Options;
use JSON::MaybeXS;

sub execute {
  my ($self, $args, $chain) = @_;
  my $app = $chain->[0];

  my $slug = $args->[0];
  unless ($slug) {
    print "Usage: arcraiders item <slug>\n";
    print "Example: arcraiders item wasp-driver\n";
    return;
  }

  # Search for item - try multiple search strategies
  my $items = $app->api->items(search => $slug);

  # If no results, try converting slug to search term (ferro-i -> ferro)
  if (!@$items && $slug =~ /-/) {
    my $search_term = $slug;
    $search_term =~ s/-[ivx]+$//i;  # Remove roman numeral suffix
    $search_term =~ s/-/ /g;        # Replace dashes with spaces
    $items = $app->api->items(search => $search_term) if $search_term ne $slug;
  }

  # Find exact match by slug or id first
  my ($item) = grep {
    ($_->slug && lc($_->slug) eq lc($slug)) ||
    ($_->id && lc($_->id) eq lc($slug))
  } @$items;

  unless ($item) {
    if (@$items == 1) {
      $item = $items->[0];
    } elsif (@$items > 1) {
      print "Multiple items match '$slug':\n";
      for my $m (@$items) {
        printf "  %s [%s]\n", $m->name // 'Unknown', $m->slug // $m->id // '-';
      }
      return;
    } else {
      print "Item '$slug' not found.\n";
      return;
    }
  }

  if ($app->json) {
    print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode($item->_raw);
    return;
  }

  _print_item_details($item);
}

sub _print_item_details {
  my ($item) = @_;

  print "=" x 60, "\n";
  printf "%s\n", $item->name // 'Unknown';
  print "=" x 60, "\n";

  _print_field("ID",          $item->slug // $item->id);
  _print_field("Category",    $item->category);
  _print_field("Rarity",      $item->rarity);
  _print_field("Weight",      $item->weight);
  _print_field("Stack Size",  $item->stack_size);
  _print_field("Base Value",  $item->base_value);

  if ($item->description) {
    print "\nDescription:\n";
    print "  ", $item->description, "\n";
  }

  if ($item->stats && %{$item->stats}) {
    print "\nStats:\n";
    for my $key (sort keys %{$item->stats}) {
      printf "  %-30s %s\n", $key, $item->stats->{$key} // '-';
    }
  }

  if ($item->crafting_requirements && @{$item->crafting_requirements}) {
    print "\nCrafting Requirements:\n";
    for my $req (@{$item->crafting_requirements}) {
      my $name = $req->{item} // $req->{name} // 'Unknown';
      my $qty  = $req->{quantity} // $req->{amount} // 1;
      printf "  %dx %s\n", $qty, $name;
    }
  }

  if ($item->sold_by && @{$item->sold_by}) {
    print "\nSold By:\n";
    for my $seller (@{$item->sold_by}) {
      if (ref $seller eq 'HASH') {
        printf "  %s\n", $seller->{name} // $seller->{trader} // 'Unknown';
      } else {
        printf "  %s\n", $seller;
      }
    }
  }

  if ($item->recycle_yield && %{$item->recycle_yield}) {
    print "\nRecycle Yield:\n";
    for my $mat (sort keys %{$item->recycle_yield}) {
      printf "  %dx %s\n", $item->recycle_yield->{$mat}, $mat;
    }
  }

  if ($item->last_updated) {
    print "\nLast Updated: ", $item->last_updated, "\n";
  }
}

sub _print_field {
  my ($label, $value) = @_;
  return unless defined $value;
  printf "%-15s %s\n", "$label:", $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::CLI::Cmd::Item - Show details for a single item

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # Show details for an item by slug
  arcraiders item wasp-driver

  # Show details for an item with roman numerals
  arcraiders item ferro-i

  # Output as JSON
  arcraiders --json item wasp-driver

=head1 DESCRIPTION

This CLI command displays detailed information for a single item in Arc Raiders.
The command searches for items by slug or ID, supporting fuzzy matching for items
with roman numeral suffixes (e.g., C<ferro-i> will search for "ferro").

If multiple items match the search term, all matches are listed. If exactly one
item matches, or an exact slug/ID match is found, detailed information is displayed
including:

=over 4

=item * Name, category, rarity

=item * Weight, stack size, base value

=item * Description and stats

=item * Crafting requirements

=item * Vendors that sell the item

=item * Recycle yield

=item * Last updated timestamp

=back

=head1 METHODS

=head2 execute

  $cmd->execute($args, $chain);

Executes the item detail command. Takes a single argument (the item slug or ID)
and displays comprehensive information about the item. If C<--json> flag is set
in the parent application, outputs raw JSON data instead of formatted text.

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
