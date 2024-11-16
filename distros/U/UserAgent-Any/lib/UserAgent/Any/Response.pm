package UserAgent::Any::Response;

use 5.036;

use Carp;
use Scalar::Util 'blessed';

use namespace::clean;

our $VERSION = 0.01;

sub new ($class, $res) {
  croak 'Passed Response object must be a blessed reference' unless blessed($res);
  if ($res isa HTTP::Response) {
    require UserAgent::Any::Response::Impl::HttpResponse;
    return UserAgent::Any::Response::Impl::HttpResponse->new(res => $res);
  } elsif ($res isa Mojo::Message::Response) {
    require UserAgent::Any::Response::Impl::MojoMessageResponse;
    return UserAgent::Any::Response::Impl::MojoMessageResponse->new(res => $res);
  } elsif ($res isa HTTP::Promise::Response) {
    require UserAgent::Any::Response::Impl::HttpPromiseResponse;
    return UserAgent::Any::Response::Impl::HttpPromiseResponse->new(res => $res);
  } elsif ($res->DOES('UserAgent::Any::Response')) {
    return $res;
  } else {
    croak 'Unknown Response type "'.ref($res).'"';
  }
}

# Do not define methods after this line, otherwise they are part of the role.
use Moo::Role;

has res => (
  is => 'ro',
  required => 1,
);

requires qw(status_code status_text success content raw_content headers header);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Response – Response object for L<UserAgent::Any>

=head1 SYNOPSIS

  my $response = $any_ua->get($url);

  if ($response->success) {
    print $response->content."\n";
  } else {
    print $response->status_code." ".$response->status_text."\n";
  }

=head1 DESCRIPTION

C<UserAgent::Any::Response> is a read-only object containing the response from
a call made by L<UserAgent::Any>.

=head2 Constructor

  my $res = UserAgent::Any::Response->new($underlying_response);

Builds a new C<UserAgent::Any::Response> object wrapping the given underlying
response. Currently supported wrapped objects are L<HTTP::Response>,
L<Mojo::Message::Response> and L<HTTP::Promise::Response>. Feel free to ask for
or contribute new implementations.

=head2 Methods

=head3 status_code

  my $code = $res->status_code;

Returns the 3 digit numerical status code of the HTTP Response.

=head3 status_text

  my $text = $res->status_text;

Returns the response status message attribute explaining the response code.

=head3 content

  my $bool = $res->success;

Returns whether the request was successful (which typically means that the
status code is in the C<200 .. 299> range).

=head3 content

  my $bytes = $res->content;

Returns the decoded response content according to the C<Content-Encoding>
header. For textual content this is turned into a Perl unicode string.

Note that this is often called C<decoded_content> in other response objects.
But, as this is what you should always use, we settled here on the simpler name.

=head3 decoded_content

  my $text = $res->decoded_content;

Returns the raw response content. This should be treated as a string of bytes.

Note that this is often called C<content> in other response objects. But in
general you don’t want to use that field unless you are doing low-level
manipulations.

=head3 headers

  my %headers = $res->headers;
  my @headers_key_value_list = $res->headers;

Returns all headers of the response. Note that this actually returns a list of
alternating keys and values and that a given key can appear more than once if a
given header appears more than once in the response.

=head3 header

  my $header = $res->header($string);
  my @headers = $res->header($string);

Returns the value of the given header. if the header appears multiple times in
the response then returns the concatenated values (separated by C<,>) in scalar
context or all the values in list content.

=head3 res

  my $obj = $res->res;

Returns the underlying response object being wrapped.

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
