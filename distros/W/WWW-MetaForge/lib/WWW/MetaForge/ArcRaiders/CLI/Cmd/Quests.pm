package WWW::MetaForge::ArcRaiders::CLI::Cmd::Quests;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List quests from the ARC Raiders API
our $VERSION = '0.002';
use Moo;
use MooX::Cmd;
use MooX::Options;
use JSON::MaybeXS;

option type => (
  is     => 'ro',
  format => 's',
  short  => 't',
  doc    => 'Filter by quest type',
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
  $params{type} = $self->type if $self->type;
  $params{page} = $self->page if $self->page;

  my ($quests, $pagination);

  if ($self->all) {
    $quests = $app->api->quests_all(%params);
  } else {
    my $result = $app->api->quests_paginated(%params);
    $quests = $result->{data};
    $pagination = $result->{pagination};
  }

  if ($app->json) {
    print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode(
      [ map { $_->_raw } @$quests ]
    );
    return;
  }

  if (!@$quests) {
    print "No quests found.\n";
    return;
  }

  for my $quest (@$quests) {
    my $name = $quest->name // 'Unknown';
    my $id   = $quest->id // '-';
    printf "%-50s  [%s]\n", $name, $id;
  }

  my $shown = scalar(@$quests);
  if ($pagination && !$self->all) {
    my $total = $pagination->{total} // '?';
    my $page_num = $pagination->{page} // 1;
    my $total_pages = $pagination->{totalPages} // '?';
    printf "\n%d quest(s) shown (page %d/%s, %s total). Use --all to fetch all pages.\n",
      $shown, $page_num, $total_pages, $total;
  } else {
    printf "\n%d quest(s) found.\n", $shown;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::CLI::Cmd::Quests - List quests from the ARC Raiders API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  arcraiders quests
  arcraiders quests --type main
  arcraiders quests --page 2
  arcraiders quests --all
  arcraiders quests --json

=head1 DESCRIPTION

Lists quests from the ARC Raiders API. By default, displays the first page
of quests. Use C<--all> to fetch all available quests across all pages.

Quest information is displayed with the quest name and ID. When JSON output
is enabled (C<--json>), the raw API response data is returned.

=head1 OPTIONS

=head2 --type, -t

Filter quests by type. Only quests matching the specified type will be returned.

  arcraiders quests --type main
  arcraiders quests -t daily

=head2 --page, -p

Specify the page number for pagination. Defaults to page 1.

  arcraiders quests --page 2
  arcraiders quests -p 3

=head2 --all, -a

Fetch all pages of quests. When enabled, pagination is handled automatically
and all quests are retrieved.

  arcraiders quests --all
  arcraiders quests -a

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
