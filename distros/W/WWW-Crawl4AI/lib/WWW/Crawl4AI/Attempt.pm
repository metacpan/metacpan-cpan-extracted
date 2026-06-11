package WWW::Crawl4AI::Attempt;
# ABSTRACT: one strategy attempt in a WWW::Crawl4AI fallback chain
use Moo;

our $VERSION = '0.001';


has backend     => ( is => 'ro', required => 1 );


has cost_class  => ( is => 'ro', default => sub { 'cheap' } );


has ok          => ( is => 'ro', default => sub { 0 } );


has page        => ( is => 'ro' );


has signals     => ( is => 'ro', default => sub { {} } );


has why_failed  => ( is => 'ro' );


has error       => ( is => 'ro' );


has elapsed     => ( is => 'ro' );


sub to_hash {
  my ( $self ) = @_;
  my $page = $self->page || {};
  return {
    backend       => $self->backend,
    cost_class    => $self->cost_class,
    ok            => $self->ok ? \1 : \0,
    status_code   => $page->{status_code},
    final_url     => $page->{final_url} // $page->{url},
    markdown_len  => defined $page->{markdown} ? length $page->{markdown} : 0,
    signals       => $self->signals,
    why_failed    => $self->why_failed,
    ( defined $self->error   ? ( error   => "@{[ $self->error ]}" ) : () ),
    ( defined $self->elapsed ? ( elapsed => $self->elapsed )        : () ),
  };
}


sub TO_JSON { $_[0]->to_hash }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Attempt - one strategy attempt in a WWW::Crawl4AI fallback chain

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $attempt = WWW::Crawl4AI::Attempt->new(
    backend    => 'crawl4ai_plain',
    cost_class => 'cheap',
    ok         => 0,
    page       => $normalized_page,
    signals    => { blocked => 1 },
    why_failed => 'bot_wall_detected',
    elapsed    => 1.42,
  );

=head1 DESCRIPTION

Records a single run of one L<WWW::Crawl4AI::Strategy> against a URL: which
backend, whether it produced a good page, the classification signals, and why
it failed if it did. The chain keeps every attempt so the final
L<WWW::Crawl4AI::Result> can explain itself to an agent.

=head2 backend

Strategy backend name, e.g. C<crawl4ai_plain>, C<crawl4ai_cloakbrowser>.

=head2 cost_class

One of C<cheap>, C<browser>, C<stealth>, C<paid>.

=head2 ok

True if this attempt's page passed classification.

=head2 page

The normalized page hashref from L<WWW::Crawl4AI::Client>, if the call returned
one.

=head2 signals

The L<WWW::Crawl4AI::Detect/signals> hashref for the page.

=head2 why_failed

Short failure token when C<ok> is false (see L<WWW::Crawl4AI::Detect/why_failed>).

=head2 error

A L<WWW::Crawl4AI::Error> or string, when the attempt threw rather than
returning a poor page.

=head2 elapsed

Wall-clock seconds the attempt took.

=head2 to_hash

A JSON-safe plain-hash view of the attempt (booleans as C<\1>/C<\0>, error
stringified). Markdown is reduced to C<markdown_len> so attempt history stays
compact.

=head2 TO_JSON

Alias for L</to_hash>, for C<< JSON::MaybeXS->new(convert_blessed => 1) >>.

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
