package UserAgent::Any::Impl::AnyEventUserAgent;

use 5.036;

use AnyEvent;
use Promise::XS;
use Moo;
use UserAgent::Any::Impl 'get_call_args', 'generate_methods', 'new_response';

use namespace::clean;

with 'UserAgent::Any';
extends 'UserAgent::Any::Impl';

our $VERSION = 0.01;

sub call {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  my $cv = AnyEvent->condvar;
  my $r;
  $this->{ua}->$method(
    $url,
    %{UserAgent::Any::Impl::params_to_hash(@{$params})},
    (defined ${$content} ? (Content => ${$content}) : ()),
    sub ($res) { $r = $res; $cv->send });
  $cv->recv;
  return new_response($r);
}

sub call_cb {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  return sub ($cb) {
    $this->{ua}->$method(
      $url,
      %{UserAgent::Any::Impl::params_to_hash(@{$params})},
      (defined ${$content} ? (Content => ${$content}) : ()),
      sub ($res) { $cb->(new_response($res)) });
    return;
  };
}

sub call_p {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  my $p = Promise::XS::deferred();
  $this->{ua}->$method(
    $url,
    %{UserAgent::Any::Impl::params_to_hash(@{$params})},
    (defined ${$content} ? (Content => ${$content}) : ()),
    sub ($res) { $p->resolve(new_response($res)) });
  return $p->promise();
}

BEGIN { generate_methods() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Impl::AnyEventUserAgent

=head1 SYNOPSIS

Implementation of L<UserAgent::Any> for the L<AnyEvent::UserAgent> class.
