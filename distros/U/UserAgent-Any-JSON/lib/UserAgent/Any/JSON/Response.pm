package UserAgent::Any::JSON::Response;

use 5.036;

use Carp;
use JSON;
use Moo;
use Scalar::Util 'blessed';

use namespace::clean;

our $VERSION = 0.01;

extends 'UserAgent::Any::Response';

has data => (
  is => 'ro',
  lazy => 1,
  # TODO: here we should maybe check the Content-Type header of the response
  # (for application/json) before proceeding.
  default => sub ($self) { return from_json($self->content) },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::JSON::Response – Response object for L<UserAgent::Any::JSON>

=head1 SYNOPSIS

  my $response = $json_client->get($url);
  print Dumper($response->data) if $response->success;

=head1 DESCRIPTION

C<UserAgent::Any::JSON::Response> is a read-only object containing the response
from a call made by L<UserAgent::Any::JSON>.

=head2 Constructor

  my $res = UserAgent::Any::Response->new($underlying_response);

Builds a new C<UserAgent::Any::JSON::Response> object wrapping the given
underlying response. See L<UserAgent::Any::Response/Constructor> for the list of
supported response objects.

In addition, this object expects that the content of the response is some JSON
encoded data.

=head2 Methods

A C<UserAgent::Any::JSON::Response> object exposes all the methods of a
L<UserAgent::Any::Response> object and add the following:

=head3 data

  my $obj = $res->data;

Returns a Perl datastructure corresponding to the decoded JSON content of the
request.

The object is decoded with the L<C<JSON::from_json>|JSON/from_json> function.

=head1 AUTHOR

Mathias Kende <mathias@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Mathias Kende

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over 4

=item *

L<HTTP::Response>

=item *

L<Mojo::Message::Response>

=back

=cut
