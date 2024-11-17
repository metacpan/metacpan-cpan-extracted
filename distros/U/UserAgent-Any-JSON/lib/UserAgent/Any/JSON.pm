package UserAgent::Any::JSON;

use 5.036;

use Carp;
use JSON;
use Moo;
use UserAgent::Any 'wrap_method';
use UserAgent::Any::JSON::Response;

use namespace::clean;

our $VERSION = 0.01;

extends 'UserAgent::Any';

# This is not specific to GET and can actually handle any verb that does not
# take a request body.
sub _generate_get_request ($self, $url, @headers) {
  croak 'Invalid number of arguments, expected an even sized list after the url' if @headers % 2;
  return _generate_post_request($self, $url, @headers);
}

# The only difference with the 'get' version is that this handles the request
# body.
sub _generate_post_request ($self, $url, @args) {
  my $body;
  $body = pop @args if @args % 2;
  return (
    $url,
    'Accept' => 'application/json',
    'Content-Type' => 'application/json',
    @args,
    defined $body ? (to_json($body)) : ());
}

sub _process_response ($self, $res, @) {
  return UserAgent::Any::JSON::Response->new($res);
}

# GET style methods
wrap_method(get => 'UserAgent::Any::get', \&_generate_get_request, \&_process_response);
wrap_method(delete => 'UserAgent::Any::delete', \&_generate_get_request, \&_process_response);
wrap_method(head => 'UserAgent::Any::head', \&_generate_get_request, \&_process_response);

# POST style methods
wrap_method(post => 'UserAgent::Any::post', \&_generate_post_request, \&_process_response);
wrap_method(patch => 'UserAgent::Any::patch', \&_generate_post_request, \&_process_response);
wrap_method(put => 'UserAgent::Any::put', \&_generate_post_request, \&_process_response);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::JSON – Specialization of UserAgent::Any for JSON APIs.

=head1 SYNOPSIS

  my $json_client = UserAgent::Any::JSON::New->new(LWP::UserAgent->new(%options));

  my $res_data = $json_client->get($url, \%url_params, \%req_data, \%headers);

=head1 DESCRIPTION

C<UserAgent::Any::JSON> is a generic client (user agent) for JSON based API,
built on top of L<UserAgent::Any>. As such, it supports synchronous and
asynchronous calls and can use many different user agent libraries.

See L<the UserAgent::Any documentation|UserAgent::Any/Supported user agents> for
the list of supported user agents, their semantics, and limitations.

=head2 Constructor

  my $json_client = UserAgent::Any::JSON->new($underlying_ua);

Builds a new C<UserAgent::Any::JSON> object wrapping the given underlying user
agent.
The wrapped object must be an instance of a
L<supported user agent|UserAgent::Any/Supported user agents>.

=head2 User agent methods

=head3 get, head, delete

  my $res_data = $json_client->get($url, %headers);

  $json_client->get_cb($url, %headers)->($cb);

  my $promise = $json_client->get_p($url, %headers);

Execute a C<GET> HTTP request to the given url. The arguments are exactly the
same as for the equivalent
L<method in UserAgent::Any|UserAgent::Any/get>. The only difference is that the
response is returned as a L<UserAgent::Any::JSON::Response> object (either
directly in the synchronous method or passed to the callback or the promise in
the asynchronous methods).

The C<head> and C<delete> methods have the exact same behavior, but using the
C<HEAD> and C<DELETE> HTTP verbs.

See the documentation of L<get() in UserAgent::Any|UserAgent::Any/get> for the
details on the asynchronous behavior of the callback and promise versions of
this method (and of all the other methods of this class).

=head3 post, patch, put

  my $res_data = $json_client->post($url, %headers, \%body);

  $json_client->post_cb($url, %headers, \%body)->($cb);

  my $promise = $json_client->post_p($url, %headers, \%body);

This is similar to the C<get> method but using the C<POST>, C<PATCH>, and C<PUT>
HTTP verbs. In addition, like the similar
L<methods in UserAgent::Any|UserAgent::Any/post> they take a last parameter for
the request body. Here, this parameter should be a reference to a Perl
data-structure that will be JSON encoded with the
L<C<JSON::to_json>|JSON/to_json> function.

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

L<LWP::UserAgent>

=item *

L<AnyEvent::UserAgent>

=item *

L<Mojo::UserAgent>

=item *

L<HTTP::Promise>

=back

=cut
