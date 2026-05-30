package WWW::Crawl4AI::Result;
# ABSTRACT: normalized result of a WWW::Crawl4AI strategy chain
use Moo;
use JSON::MaybeXS ();
use URI ();

our $VERSION = '0.001';


has ok         => ( is => 'ro', default => sub { 0 } );


has url        => ( is => 'ro' );


has final_url  => ( is => 'ro' );


has status     => ( is => 'ro' );


has markdown   => ( is => 'ro' );


has html       => ( is => 'ro' );


has title      => ( is => 'ro' );


has backend    => ( is => 'ro' );


has cost_class => ( is => 'ro' );


has signals    => ( is => 'ro', default => sub { {} } );


has why_failed => ( is => 'ro' );


has error      => ( is => 'ro' );


has attempts   => ( is => 'ro', default => sub { [] } );


has links      => ( is => 'ro', default => sub { { internal => [], external => [] } } );


has _json => (
  is      => 'lazy',
  default => sub { JSON::MaybeXS->new( utf8 => 0, canonical => 1, convert_blessed => 1 ) },
);

sub from_attempt {
  my ( $class, $attempt, %extra ) = @_;
  my $page = $attempt->page || {};
  return $class->new(
    ok         => $attempt->ok,
    url        => $page->{url},
    final_url  => $page->{final_url} // $page->{url},
    status     => $page->{status_code},
    markdown   => $page->{markdown},
    html       => $page->{html},
    title      => $page->{title},
    backend    => $attempt->backend,
    cost_class => $attempt->cost_class,
    signals    => $attempt->signals,
    why_failed => $attempt->why_failed,
    links      => $page->{links} // { internal => [], external => [] },
    %extra,
  );
}


sub attempt_count { scalar @{ $_[0]->attempts } }


sub internal_links { $_[0]->links->{internal} || [] }


sub external_links { $_[0]->links->{external} || [] }


sub urls {
  my ( $self ) = @_;
  my $base = $self->final_url // $self->url;
  my ( %seen, @urls );
  for my $link ( @{ $self->internal_links }, @{ $self->external_links } ) {
    my $href = ref $link eq 'HASH' ? $link->{href} : $link;
    next unless defined $href && length $href;
    next if $href =~ m{\A(?:javascript|mailto|tel|data):}i;
    next if $href =~ /\A#/;
    my $abs = $base ? URI->new_abs( $href, $base )->as_string : $href;
    next unless $abs =~ m{\Ahttps?://}i;
    next if $seen{$abs}++;
    push @urls, $abs;
  }
  return \@urls;
}


sub to_hash {
  my ( $self ) = @_;
  return {
    ok         => $self->ok ? \1 : \0,
    url        => $self->url,
    final_url  => $self->final_url,
    status     => $self->status,
    backend    => $self->backend,
    cost_class => $self->cost_class,
    title      => $self->title,
    markdown   => $self->markdown,
    signals    => $self->signals,
    why_failed => $self->why_failed,
    links      => $self->links,
    urls       => $self->urls,
    ( defined $self->error ? ( error => "@{[ $self->error ]}" ) : () ),
    attempts   => [ map { $_->to_hash } @{ $self->attempts } ],
  };
}


sub TO_JSON { $_[0]->to_hash }

sub attempts_json {
  my ( $self ) = @_;
  return $self->_json->encode( [ map { $_->to_hash } @{ $self->attempts } ] );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Result - normalized result of a WWW::Crawl4AI strategy chain

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $result = $crawler->markdown('https://example.com');

  if ( $result->ok ) {
    print $result->markdown;
    print $result->backend;     # which strategy won
    print $result->cost_class;  # cheap / browser / stealth / paid
  }
  else {
    warn $result->why_failed;   # 'bot_wall_detected'
    print $result->attempts_json;
  }

=head1 DESCRIPTION

The single, uniform object every L<WWW::Crawl4AI> crawl returns, regardless of
which backend won (or that they all lost). It carries the winning content plus
the full L<WWW::Crawl4AI::Attempt> history, so callers — especially agents —
can see I<why> a backend was chosen or I<why> everything failed.

=head2 ok

True if some strategy produced a good page.

=head2 url

The original requested URL.

=head2 final_url

The URL after redirects, when known.

=head2 status

HTTP status code of the winning (or last) attempt.

=head2 markdown

Content of the winning page.

=head2 html

Raw HTML of the winning page.

=head2 title

Page title of the winning page.

=head2 backend

Name of the strategy that won, e.g. C<crawl4ai_stealth>.

=head2 cost_class

Cost tier of the winning backend: C<cheap>, C<browser>, C<stealth>, C<paid>.

=head2 signals

The L<WWW::Crawl4AI::Detect/signals> of the winning (or last) page.

=head2 why_failed

When C<ok> is false, the failure token of the last attempt.

=head2 error

A L<WWW::Crawl4AI::Error> or string when the chain failed outright.

=head2 attempts

Arrayref of L<WWW::Crawl4AI::Attempt> objects, in execution order.

=head2 links

The links Crawl4AI extracted from the winning page, as
C<< { internal => [...], external => [...] } >>. Each entry is a hashref with
C<href>, C<text> and C<title>. For just the URLs, use L</urls>.

=head2 from_attempt

  WWW::Crawl4AI::Result->from_attempt($attempt, attempts => \@all)

Builds a result from a winning attempt, copying its page content over.

=head2 attempt_count

Number of attempts made.

=head2 internal_links

Arrayref of the winning page's same-site links (each C<< { href, text, title } >>).

=head2 external_links

Arrayref of the winning page's off-site links (each C<< { href, text, title } >>).

=head2 urls

The deduplicated, absolute C<http>/C<https> URLs found on the winning page,
internal links first then external. Relative hrefs are resolved against L</final_url>;
C<javascript:>, C<mailto:>, C<tel:>, C<data:> and bare anchors are dropped. This
is the list to feed back into a crawl to go deeper.

=head2 to_hash

=head2 TO_JSON

JSON-safe plain-hash view, including every attempt via
L<WWW::Crawl4AI::Attempt/to_hash>.

=head2 attempts_json

The attempt history encoded as a JSON string.

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
