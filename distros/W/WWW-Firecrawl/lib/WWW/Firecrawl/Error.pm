package WWW::Firecrawl::Error;
# ABSTRACT: structured error class for WWW::Firecrawl
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
has attempt     => ( is => 'ro' );

sub is_transport { $_[0]->type eq 'transport' }
sub is_api       { $_[0]->type eq 'api' }
sub is_job       { $_[0]->type eq 'job' }
sub is_scrape    { $_[0]->type eq 'scrape' }
sub is_page      { $_[0]->type eq 'page' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Firecrawl::Error - structured error class for WWW::Firecrawl

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  die WWW::Firecrawl::Error->new(
    type        => 'api',
    message     => "HTTP 503: Service Unavailable",
    response    => $http_response,
    status_code => 503,
    attempt     => 3,
  );

  if (my $e = $@) {
    if (ref $e && $e->isa('WWW::Firecrawl::Error')) {
      warn "firecrawl failed at @{[ $e->type ]}: $e" if $e->is_api;
    }
  }

=head2 type

One of C<transport>, C<api>, C<job>, C<scrape>, C<page>. Required.

=head2 message

Human-readable error string. Required. The object stringifies to this.

=head2 response

The L<HTTP::Response> object, when available.

=head2 data

The decoded JSON payload, when available.

=head2 status_code

For C<transport>/C<api> this is the HTTP status code of the Firecrawl response
(0 for pure transport failures). For C<scrape>/C<page> this is
C<data.metadata.statusCode> of the target page. Undef for C<job>.

=head2 url

Target URL for C<scrape> and C<page> errors.

=head2 attempt

1-based attempt counter, populated when retry was involved.

=head2 is_transport

=head2 is_api

=head2 is_job

=head2 is_scrape

=head2 is_page

Boolean accessors, each returns true when L</type> matches.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-firecrawl/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
