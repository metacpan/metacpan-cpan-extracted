package UserAgent::Any::Impl::HttpPromise;

use 5.036;

use HTTP::Promise;
use Moo;
use Promise::Me;
use UserAgent::Any::Impl 'get_call_args', 'generate_methods', 'new_response';

use namespace::clean;

with 'UserAgent::Any';
extends 'UserAgent::Any::Impl';

our $VERSION = 0.01;

sub call {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  my $p = $this->{ua}->$method(
    $url,
    %{UserAgent::Any::Impl::params_to_hash(@{$params})},
    (defined ${$content} ? (Content => ${$content}) : ())
  )->then(sub { return $_[0] });
  my @r = await($p);
  return new_response(@r);
}

sub call_cb {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  return sub ($cb) {
    $this->{ua}->$method(
      $url,
      %{UserAgent::Any::Impl::params_to_hash(@{$params})},
      (defined ${$content} ? (Content => ${$content}) : ())
    )->then(sub { $cb->(new_response($_[0])) });
    return;
  }
}

sub call_p {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  return $this->{ua}->$method(
    $url,
    %{UserAgent::Any::Impl::params_to_hash(@{$params})},
    (defined ${$content} ? (Content => ${$content}) : ())
  )->then(sub { new_response($_[0]) });
}

BEGIN { generate_methods() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Impl::HttpPromise

=head1 SYNOPSIS

Implementation of L<UserAgent::Any> for the L<HTTP::Promise> class.
