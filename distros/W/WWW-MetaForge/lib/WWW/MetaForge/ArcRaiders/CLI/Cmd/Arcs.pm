package WWW::MetaForge::ArcRaiders::CLI::Cmd::Arcs;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List ARCs from the ARC Raiders API
our $VERSION = '0.002';
use Moo;
use MooX::Cmd;
use MooX::Options;
use JSON::MaybeXS;

option loot => (
  is    => 'ro',
  short => 'l',
  doc   => 'Include loot drop information',
);

option page => (
  is     => 'ro',
  format => 'i',
  short  => 'p',
  doc    => 'Page number for pagination',
);

option all => (
  is    => 'ro',
  short => 'a',
  doc   => 'Fetch all pages',
);

sub execute {
  my ($self, $args, $chain) = @_;
  my $app = $chain->[0];

  my %params;
  $params{includeLoot} = 1 if $self->loot;
  $params{page} = $self->page if $self->page;

  my ($arcs, $pagination);

  if ($self->all) {
    $arcs = $app->api->arcs_all(%params);
  } else {
    my $result = $app->api->arcs_paginated(%params);
    $arcs = $result->{data};
    $pagination = $result->{pagination};
  }

  if ($app->json) {
    print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode(
      [ map { $_->_raw } @$arcs ]
    );
    return;
  }

  if (!@$arcs) {
    print "No ARCs found.\n";
    return;
  }

  for my $arc (@$arcs) {
    my $name = $arc->name // 'Unknown';
    my $id   = $arc->id // '-';
    printf "%-40s  [%s]\n", $name, $id;
  }

  my $shown = scalar(@$arcs);
  if ($pagination && $pagination->{totalPages} > 1 && !$self->all) {
    my $total = $pagination->{total} // '?';
    my $page_num = $pagination->{page} // 1;
    my $total_pages = $pagination->{totalPages} // '?';
    printf "\n%d ARC(s) shown (page %d/%s, %s total). Use --all to fetch all pages.\n",
      $shown, $page_num, $total_pages, $total;
  } else {
    printf "\n%d ARC(s) found.\n", $shown;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::CLI::Cmd::Arcs - List ARCs from the ARC Raiders API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # List ARCs (first page)
  arcraiders arcs

  # Include loot drop information
  arcraiders arcs --loot
  arcraiders arcs -l

  # Navigate to specific page
  arcraiders arcs --page 2
  arcraiders arcs -p 3

  # Fetch all pages
  arcraiders arcs --all
  arcraiders arcs -a

  # Combine options
  arcraiders arcs --loot --all

  # JSON output
  arcraiders --json arcs

=head1 DESCRIPTION

This command retrieves and displays a list of ARCs (enemies) from the ARC Raiders
game API. By default, it shows the first page of results with basic information
about each ARC including name and ID.

Results are paginated by the API. Use C<--page> to navigate pages or C<--all> to
fetch all available ARCs across all pages.

=head1 OPTIONS

=head2 --loot, -l

Include loot drop information for each ARC. When enabled, the API returns additional
details about what items each ARC can drop.

=head2 --page PAGE, -p PAGE

Retrieve a specific page number. Pages are 1-indexed. Without this option, the first
page is returned.

Cannot be combined with C<--all>.

=head2 --all, -a

Fetch all pages automatically. When enabled, the command retrieves every page of
results and displays all ARCs in a single list.

This may take longer depending on the total number of ARCs.

=head1 OUTPUT

In normal mode, outputs a formatted list with each ARC on its own line:

  ARC Name                                  [ID]
  Another ARC                               [42]

At the end, displays a summary:

  2 ARC(s) found.

For paginated results (without C<--all>), the summary includes pagination details:

  10 ARC(s) shown (page 1/5, 50 total). Use --all to fetch all pages.

With C<--json> global option, outputs raw API response as JSON array.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-metaforge/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
