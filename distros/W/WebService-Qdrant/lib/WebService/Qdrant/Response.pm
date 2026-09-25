package WebService::Qdrant::Response;
use 5.020;
use strict;
use warnings;

our $VERSION = '0.0001'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY

use Moo;
use JSON::MaybeXS;

has http_code => (is => 'ro', required => 1);
has raw_content => (is => 'ro', default => sub { '' });
has json_response => (is => 'ro', lazy => 1, builder => '_decode');
has decode_error => (is => 'ro', writer => '_set_decode_error');

sub _decode {
   my ($self) = @_;
   my $data = eval {
      JSON::MaybeXS->new(utf8 => 1)->decode($self->raw_content);
   };
   $self->_set_decode_error($@) if $@;
   return $data;
}

sub BUILD {
   my ($self) = @_;
   $self->json_response;
   return;
}

sub is_success {
   my ($self) = @_;
   return $self->http_code >= 200 && $self->http_code < 300;
}

sub _field {
   my ($self, $name) = @_;
   my $data = $self->json_response;
   return ref($data) eq 'HASH' ? $data->{$name} : undef;
}

sub result { return shift->_field('result'); }
sub status { return shift->_field('status'); }
sub time   { return shift->_field('time'); }
sub usage  { return shift->_field('usage'); }

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::Qdrant::Response - Qdrant HTTP response and decoded JSON

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    my $response = $qdrant->get_collection(collection_name => 'notes');
    if ($response->is_success && !defined $response->decode_error) {
        my $configuration = $response->result;
    } else {
        warn $response->raw_content;
    }

=head1 DESCRIPTION

Represents one completed HTTP exchange. Qdrant results remain ordinary Perl
hashes, arrays, scalars, and JSON booleans. HTTP errors do not throw. A body
that cannot be decoded is retained with a decoding diagnostic.

=head1 SUBROUTINES/METHODS

=head2 new

    my $response = WebService::Qdrant::Response->new(
        http_code   => 200,
        raw_content => '{"status":"ok","result":{"exists":false}}',
    );

Requires C<http_code>. C<raw_content> defaults to an empty string and is
expected to contain UTF-8 JSON bytes. The body is decoded once.

=head2 is_success

True for HTTP codes 200 through 299. This describes the HTTP outcome only;
it does not imply that the body is valid JSON or that a result is true.

=head2 json_response

The complete decoded JSON value, preserving unknown fields. Returns undef
on decoding failure or for JSON null; C<decode_error> distinguishes these.

=head2 result

Returns the decoded operation result.

=head2 status

Returns the Qdrant status string or error hash.

=head2 time

Returns the server-reported processing time.

Read the corresponding top-level Qdrant envelope field. Missing fields or
a non-object JSON body return undef. C<status> may be a string or an error
hash. C<result> can include a false boolean or an empty list without implying
an HTTP failure. C<time> is the server-reported processing time.

=head2 usage

Returns the decoded top-level usage information, preserving its nested
structure for inspection or debugging. Returns undef when usage is absent
or the response body is not a JSON object.

=head1 ATTRIBUTES

=head2 http_code

Numeric HTTP status code.

=head2 raw_content

Response body bytes after HTTP content decoding, before JSON decoding.
Available even for HTML, empty, or malformed responses.

=head2 decode_error

JSON decoding diagnostic, or undef on successful decoding. Invalid JSON
never causes construction to throw. An empty body produces a diagnostic.

=head1 SEE ALSO

L<WebService::Qdrant>, L<WebService::Qdrant::UA>

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Qdrant HTTP response and decoded JSON

