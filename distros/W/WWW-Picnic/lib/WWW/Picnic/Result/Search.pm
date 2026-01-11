package WWW::Picnic::Result::Search;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Picnic search results collection

use Moo;

extends 'WWW::Picnic::Result';

use WWW::Picnic::Result::SearchResult;


# Recursively find all sellingUnit objects in the response
sub _find_selling_units {
  my ($self, $data, $seen) = @_;
  $seen //= {};
  my @units;

  return @units unless ref $data;

  if (ref $data eq 'HASH') {
    # Found a sellingUnit
    if (exists $data->{sellingUnit} && ref $data->{sellingUnit} eq 'HASH') {
      my $unit = $data->{sellingUnit};
      my $id = $unit->{id};
      # Deduplicate by ID
      unless ($seen->{$id}++) {
        push @units, $unit;
      }
    }
    # Recurse into hash values
    for my $val (values %$data) {
      push @units, $self->_find_selling_units($val, $seen);
    }
  }
  elsif (ref $data eq 'ARRAY') {
    # Recurse into array elements
    for my $elem (@$data) {
      push @units, $self->_find_selling_units($elem, $seen);
    }
  }

  return @units;
}

has items => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my @units = $self->_find_selling_units($self->raw);
    return [ map { WWW::Picnic::Result::SearchResult->new($_) } @units ];
  },
);


sub all_items {
  my ( $self ) = @_;
  return @{ $self->items };
}


sub total_count {
  my ( $self ) = @_;
  return scalar @{ $self->items };
}


sub first_group_id {
  my ( $self ) = @_;
  my $raw = $self->raw;
  # Try to extract from analytics context
  if (ref $raw eq 'HASH' && $raw->{body} && $raw->{body}{child}) {
    my $analytics = $raw->{body}{child}{analytics};
    if ($analytics && $analytics->{contexts}) {
      for my $ctx (@{$analytics->{contexts}}) {
        return $ctx->{data}{main_entity} if $ctx->{data} && $ctx->{data}{main_entity};
      }
    }
  }
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::Search - Picnic search results collection

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    my $search = $picnic->search('haribo');
    say "Found ", $search->total_count, " results";

    for my $item ($search->all_items) {
        say $item->name, " - ", $item->display_price;
    }

=head1 DESCRIPTION

Container for search results from the Picnic API. Extracts selling units
from the deeply nested response structure.

=head2 items

Arrayref of L<WWW::Picnic::Result::SearchResult> objects extracted
from the search response.

=head2 all_items

Returns list of all search result items.

=head2 total_count

Returns total number of items found.

=head2 first_group_id

Returns the main search entity (usually matches the search term).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-picnic/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
