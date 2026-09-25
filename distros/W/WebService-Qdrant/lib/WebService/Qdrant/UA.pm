package WebService::Qdrant::UA;
use 5.020;
use strict;
use warnings;

our $VERSION = '0.0001'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY

use Moo;
use Carp qw(croak);
use LWP::UserAgent;
use HTTP::Request;
use JSON::MaybeXS;
use URI;
use WebService::Qdrant::Response;

has base_url => (is => 'ro', default => sub { 'http://localhost:6333' });
has api_key => (is => 'ro');
has timeout => (is => 'ro', default => sub { 30 });
has ua => (
   is => 'ro',
   lazy => 1,
   default => sub {
      my ($self) = @_;
      my $ua = LWP::UserAgent->new(timeout => $self->timeout);
      $ua->default_header('api-key' => $self->api_key)
         if defined $self->api_key;
      return $ua;
   },
);
has json => (
   is => 'ro',
   default => sub { JSON::MaybeXS->new(utf8 => 1) },
);

sub get    { return shift->request(@_, type => 'GET'); }
sub put    { return shift->request(@_, type => 'PUT'); }
sub post   { return shift->request(@_, type => 'POST'); }
sub delete { return shift->request(@_, type => 'DELETE'); }

sub request {
   my ($self, %params) = @_;
   my $type = $params{type} // '';
   croak 'Unsupported HTTP method' unless $type =~ /\A(?:GET|PUT|POST|DELETE)\z/;
   croak 'A relative endpoint path beginning with / is required'
      unless defined $params{url} && $params{url} =~ m{\A/(?!/)};
   my $base = $self->base_url;
   $base =~ s{/+\z}{};
   my $url = URI->new($base . $params{url});
   if (defined $params{query}) {
      my %query = %{$params{query}};
      for my $value (values %query) {
         $value = $value ? 'true' : 'false'
            if JSON::MaybeXS::is_bool($value);
      }
      $url->query_form(\%query);
   }
   my $request = HTTP::Request->new($type => $url);
   $request->header(Accept => 'application/json');
   if (defined $params{data}) {
      $request->header('Content-Type' => 'application/json');
      $request->content($self->json->encode($params{data}));
   }
   return $self->response($self->ua->request($request));
}

sub response {
   my ($self, $http) = @_;
   if (($http->header('Client-Warning') // '') eq 'Internal response') {
      croak $http->status_line . ': ' . $http->decoded_content;
   }
   return WebService::Qdrant::Response->new(
      http_code => $http->code,
      raw_content => $http->decoded_content(charset => 'none'),
   );
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::Qdrant::UA - HTTP transport for Qdrant

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    my $ua = WebService::Qdrant::UA->new(
        base_url => 'http://localhost:6333',
        timeout  => 30,
    );
    my $response = $ua->put(
        url   => '/collections/notes',
        query => { timeout => 10 },
        data  => { vectors => { size => 3, distance => 'Cosine' } },
    );

=head1 DESCRIPTION

Sends ordinary JSON requests using L<LWP::UserAgent>. Every server response,
including HTTP errors and malformed JSON, becomes a
L<WebService::Qdrant::Response>. Transport failures throw exceptions.

=head1 SUBROUTINES/METHODS

=head2 new

Accepts the attributes below. Construction does not contact the server.

=head2 get

Sends a GET request.

=head2 put

Sends a PUT request.

=head2 post

Sends a POST request.

=head2 delete

Sends a DELETE request.

HTTP method shortcuts accepting C<url>, optional C<query> (a hash reference
of URL parameters), and optional C<data> (the JSON body). The endpoint path
must begin with one slash and should already contain escaped path segments.
The base URL may end with a slash. JSON boolean query values become the text
C<true> or C<false>. Arguments are not modified.

Omitting C<data> sends no body. An empty hash reference sends a JSON object.
URL parameters and JSON body fields are deliberately separate.

=head2 request

Accepts the same arguments and a C<type> of C<GET>, C<PUT>, C<POST>, or
C<DELETE>. Returns one response object.

=head2 response

Converts an L<HTTP::Response> into a Qdrant response. LWP synthetic responses
marked C<Client-Warning: Internal response> throw with the transport error.
A server HTTP 500 without that marker is returned normally.

=head1 ATTRIBUTES

=head2 base_url

Service URL; defaults to C<http://localhost:6333>.

=head2 api_key

Optional key set as the default C<api-key> header on the generated HTTP client.

=head2 timeout

LWP timeout in seconds, default C<30>. Separate from Qdrant operation timeouts.

=head2 ua

Optional injected LWP-compatible HTTP client. Used as supplied; configure its
headers and timeout yourself. Otherwise constructed lazily and reused.

=head2 json

JSON encoder, default L<JSON::MaybeXS> configured for UTF-8 bytes.

=head1 DIAGNOSTICS

Invalid request arguments and JSON encoding failures throw, as do transport
failures such as refused connections, DNS errors, and timeouts. Completed HTTP
exchanges return response objects even when the server reports an error.

=head1 SEE ALSO

L<WebService::Qdrant>, L<WebService::Qdrant::Response>

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: HTTP transport for Qdrant

