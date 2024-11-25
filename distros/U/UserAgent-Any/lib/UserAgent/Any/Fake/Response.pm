package UserAgent::Any::Fake::Response;

use 5.036;

use Moo;
use Readonly;
use UserAgent::Any::Impl::Helper 'params_to_hash';

use namespace::clean;

our $VERSION = 0.01;

extends 'UserAgent::Any::Response';
with 'UserAgent::Any::Response::Impl';

has '+_impl' => (required => 0,);

has '+res' => (required => 0,);

has [qw(status_code status_text content _headers)] => (is => 'rw',);

Readonly my $HTTP_STATUS_CODE_SUCCESS_MIN => 200;
Readonly my $HTTP_STATUS_CODE_SUCCESS_MAX => 299;

sub success ($self) {
  return $HTTP_STATUS_CODE_SUCCESS_MIN <= $self->status_code <= $HTTP_STATUS_CODE_SUCCESS_MAX;
}

sub raw_content ($self, $content = undef) {
  return $self->content($content) if defined $content;
  return $self->content;
}

sub header ($self, $k, $val = undef) {
  if (defined $val) {
    $self->_headers->{$k} = $val;
    return;
  }
  my $v = $self->_headers->{$k};
  return unless defined $v;
  return $v unless ref($v);
  return @{$v} if wantarray;
  return join(',', @{$v});
}

sub headers ($self, @headers) {
  if (@headers) {
    $self->_headers(params_to_hash(@headers));
    return;
  }

  my @all_headers;
  for my $k (sort keys %{$self->_headers}) {
    push @all_headers, map { ($k, $_) } $self->header($k);
  }
  return @all_headers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Fake::Response

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

There is no handling of the content encoding and content charset in this fake
object. So you should always just fill the C<content> directly and not rely on
C<raw_content>.

=item *

The headers returned by C<headers()> are sorted by names (and the order of their
values is preserved from the input). This is to help write deterministic tests
but this is B<not> the behavior of the real implementations.

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
