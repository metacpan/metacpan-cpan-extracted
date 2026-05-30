package WWW::Crawl4AI::DeepCrawlIterator;
# ABSTRACT: breadth-first iterator for deep_crawl, separating frontier management from crawl logic
use Moo;

our $VERSION = '0.001';


has crawler => (
  is       => 'ro',
  required => 1,
);


has start_url => (
  is       => 'ro',
  required => 1,
);


has max_pages => (
  is      => 'ro',
  default => sub { 25 },
);


has max_depth => (
  is      => 'ro',
  default => sub { 2 },
);


has same_host => (
  is      => 'ro',
  default => sub { 1 },
);


has url_filter => (
  is      => 'ro',
  builder => 1,
);


sub _build_url_filter { undef }

has on_page => (
  is      => 'ro',
  builder => 1,
);


sub _build_on_page { undef }

# Internal state
has _seen        => ( is => 'rwp', default => sub { {} } );
has _queue       => ( is => 'rwp', default => sub { [] } );
has _results     => ( is => 'rwp', default => sub { [] } );
has _start_host  => ( is => 'rw' );
has _crawled => ( is => 'rw', default => sub { 0 } );

sub _canon_url {
  my ( $self, $url ) = @_;
  require URI;
  my $u = eval { URI->new($url) } or return $url;
  $u->fragment(undef);
  return $u->as_string;
}

sub _host_eq {
  my ( $self, $url ) = @_;
  require URI;
  my $host = lc( eval { URI->new($url)->host } // '' );
  return $host eq ( $self->_start_host // '' );
}


sub next {
  my ( $self ) = @_;

  # Seed the queue on first call
  if ( $self->_crawled == 0 && !@{ $self->_queue } ) {
    $self->_push_url( $self->start_url, 0 );
  }

  # Exhausted?
  return undef unless @{ $self->_queue };
  return undef if @{ $self->_results } >= $self->max_pages;

  my $node = shift @{ $self->_queue };
  my $result = $self->crawler->crawl( $node->{url} );
  push @{ $self->_results }, $result;
  $self->_crawled( $self->_crawled + 1 );

  my $depth = $node->{depth};
  $self->on_page->( $result, $depth ) if $self->on_page;

  # Lock start_host from the first real crawl (handles redirects)
  if ( !defined $self->_start_host && $result->final_url ) {
    require URI;
    $self->_start_host(
      lc( eval { URI->new( $result->final_url )->host } // '' ) );
  }

  # Schedule links if not at max depth and result is good
  if ( $depth < $self->max_depth && $result->ok ) {
    for my $url ( @{ $result->urls } ) {
      next if $self->same_host && !$self->_host_eq($url);
      next if $self->url_filter && !$self->url_filter->($url);
      $self->_push_url( $url, $depth + 1 );
    }
  }

  return [ $result, $depth ];
}

sub _push_url {
  my ( $self, $url, $depth ) = @_;
  my $canon = $self->_canon_url($url);
  return if $self->_seen->{$canon}++;
  push @{ $self->_queue }, { url => $url, depth => $depth };
}


sub results { $_[0]->_results }


sub is_exhausted {
  my ( $self ) = @_;
  return !@{ $self->_queue } || @{ $self->_results } >= $self->max_pages;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::DeepCrawlIterator - breadth-first iterator for deep_crawl, separating frontier management from crawl logic

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $iter = WWW::Crawl4AI::DeepCrawlIterator->new(
    crawler   => $crawler,
    start_url => 'https://example.com',
    max_pages => 50,
    max_depth => 3,
    same_host => 1,
    url_filter => sub { $_[0] !~ m{/login} },
  );

  while ( my $page = $iter->next ) {
    my ( $result, $depth ) = @$page;
    $on_page->( $result, $depth ) if $on_page;
  }

=head1 DESCRIPTION

Iterator over pages returned by L<WWW::Crawl4AI/deep_crawl>. Encapsulates the BFS
frontier management: deduplication, same-host filtering, depth capping. Each call
to L</next> performs one crawl (through the strategy chain) and schedules its
links for future traversal.

Replaces the inline BFS loop in C<WWW::Crawl4AI::deep_crawl>, enabling alternative
crawl orders and isolated testing of the frontier logic.

=head2 crawler

A L<WWW::Crawl4AI> instance (or any object with a C<crawl> method).

=head2 start_url

Starting URL for the crawl.

=head2 max_pages

Hard cap on pages crawled.

=head2 max_depth

Maximum link-following depth; the start URL is depth C<0>.

=head2 same_host

Only follow links on the start URL's host.

=head2 url_filter

Optional coderef C<< ($url) -> bool >>; return false to skip a URL.

=head2 on_page

Optional coderef C<< ($result, $depth) >> called as each page completes.

=head2 next

Returns an arrayref C<< [$result, $depth] >> for the next page, or C<undef> when
the crawl is exhausted or C<max_pages> reached.

=head2 results

Returns the arrayref of L<WWW::Crawl4AI::Result> accumulated so far.

=head2 is_exhausted

True when the queue is empty or C<max_pages> reached.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-crawl4ai/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
