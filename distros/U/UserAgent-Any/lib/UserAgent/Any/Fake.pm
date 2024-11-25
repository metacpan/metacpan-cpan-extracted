package UserAgent::Any::Fake;

use 5.036;

use Carp;
use Moo;
use Scalar::Util 'blessed';
use UserAgent::Any::Fake::Request;
use UserAgent::Any::Fake::Response;
use UserAgent::Any::Impl::Helper 'generate_methods';

use namespace::clean;

our $VERSION = 0.01;

extends 'UserAgent::Any';
with 'UserAgent::Any::Impl';

has '+_impl' => (required => 0,);
has '+ua' => (required => 0,);

has _handler => (is => 'ro',);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  return {_handler => $args[0]}
      if @args == 1 && (ref($args[0]) ne 'HASH' || !blessed($args[0]));

  return $class->$orig(@args);
};

sub call ($self, @args) {
  my $req = UserAgent::Any::Fake::Request->new(@args);
  my $res = UserAgent::Any::Fake::Response->new(status_code => 200, status_text => 'SUCCESS');
  $self->_handler->($req, $res);
  return $res;
}

sub call_cb ($self, $url, %params) {
  croak 'UserAgent::Any async methods are not implemented with UserAgent::Any::Fake';
}

sub call_p ($self, $url, %params) {
  croak 'UserAgent::Any async methods are not implemented with UserAgent::Any::Fake';
}

BEGIN { generate_methods() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Fake – Fake implementation of UserAgent::Any to be used in tests
of derived classes.

=head1 SYNOPSIS

  sub fake_handler ($req, $res) {
    if ($req->method eq 'GET' && $req->header('X-test') eq 'Foo') {
      $res->status_code(404);
      $res->header(Foo => 'bar');
      $res->header(Baz => [qw(abc def)]);
    }
  }

  my $fake_ua = UserAgent::Any::Fake->new(\&handler);
  ok(call_that_expect_a_useragent_any($fake_ua));

=head1 DESCRIPTION

See the synopsis for now.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

This fake implementation does not handle asynchronous calls. In general, if you
are testing a library deriving from L<UserAgent::Any> this is not an issue
because you should use the L<UserAgent::Any::Wrapper> helper to generate the
asynchronous calls and, as such, you don’t need to test them.

=back

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

L<UserAgent::Any>

=item *

L<UserAgent::Any::Wrapper>

=item *

L<UserAgent::Any::Response>

=back

=cut
