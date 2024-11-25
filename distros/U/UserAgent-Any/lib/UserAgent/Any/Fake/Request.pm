package UserAgent::Any::Fake::Request;

use 5.036;

use UserAgent::Any::Impl::Helper 'params_to_hash';
use Moo;

use namespace::clean;

our $VERSION = 0.01;

has [qw(url method _headers content)] => (is => 'ro',);

around BUILDARGS => sub {
  my ($orig, $class, $method, $url, @args) = @_;

  my $content;
  $content = pop @args if @args % 2;

  return {
    url => $url,
    method => $method,
    _headers => params_to_hash(@args),
    content => $content
  };
};

sub header ($self, $k) {
  my $v = $self->_headers->{$k};
  return unless defined $v;
  return $v unless ref($v);
  return @{$v} if wantarray;
  return join(',', @{$v});
}

sub headers ($self) {
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

UserAgent::Any::Fake::Request

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
