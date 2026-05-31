package WWW::Crawl4AI::Error;
# ABSTRACT: structured error class for WWW::Crawl4AI
use Moo;
use overload
  '""' => sub { $_[0]->message },
  bool => sub { 1 },
  fallback => 1;

our $VERSION = '0.001';


has type        => ( is => 'ro', required => 1 );


has message     => ( is => 'ro', required => 1 );


has response    => ( is => 'ro' );


has data        => ( is => 'ro' );


has status_code => ( is => 'ro' );


has url         => ( is => 'ro' );


has backend     => ( is => 'ro' );


has attempt     => ( is => 'ro' );


sub is_transport { $_[0]->type eq 'transport' }
sub is_api       { $_[0]->type eq 'api' }
sub is_job       { $_[0]->type eq 'job' }
sub is_content   { $_[0]->type eq 'content' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Error - structured error class for WWW::Crawl4AI

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  die WWW::Crawl4AI::Error->new(
    type        => 'api',
    message     => "HTTP 503: Service Unavailable",
    response    => $http_response,
    status_code => 503,
    backend     => 'crawl4ai_plain',
  );

  if (my $e = $@) {
    if (ref $e && $e->isa('WWW::Crawl4AI::Error')) {
      warn "crawl4ai failed (@{[ $e->type ]}): $e" if $e->is_api;
    }
  }

=head1 DESCRIPTION

Structured error thrown by L<WWW::Crawl4AI::Client> and the strategy chain.
Stringifies to its C<message> so it works as a drop-in replacement for a
string exception. Carries type, HTTP context, and the responsible backend so
callers can route on the specific kind of failure.

=head2 type

One of C<transport>, C<api>, C<job>, C<content>. Required.

=over 4

=item C<transport> — could not reach the Crawl4AI server at all.

=item C<api> — the server responded with an HTTP error or malformed body.

=item C<job> — an async job finished with status C<FAILED>.

=item C<content> — every strategy ran but no result passed classification
(used as the error type of a failed L<WWW::Crawl4AI::Result>).

=back

=head2 message

Human-readable error string. Required. The object stringifies to this.

=head2 response

The L<HTTP::Response> object, when available.

=head2 data

The decoded JSON payload, when available.

=head2 status_code

HTTP status code of the Crawl4AI response (0 for pure transport failures).

=head2 url

Target URL, when the error is tied to one.

=head2 backend

Name of the strategy backend that produced the error, e.g. C<crawl4ai_plain>.

=head2 attempt

1-based attempt counter, populated when retry was involved.

=head2 is_transport

=head2 is_api

=head2 is_job

=head2 is_content

Boolean accessors, each returns true when L</type> matches.

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
