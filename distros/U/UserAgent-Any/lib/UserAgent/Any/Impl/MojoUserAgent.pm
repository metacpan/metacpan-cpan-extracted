package UserAgent::Any::Impl::MojoUserAgent;

use 5.036;

use Moo;
use UserAgent::Any::Impl 'get_call_args', 'generate_methods', 'new_response';

use namespace::clean;

with 'UserAgent::Any';
extends 'UserAgent::Any::Impl';

our $VERSION = 0.01;

sub call {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  return new_response(
    $this->{ua}->$method(
      $url,
      UserAgent::Any::Impl::params_to_hash(@{$params}),
      (defined ${$content} ? ${$content} : ())
    )->res);
}

sub call_cb {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  return sub ($cb) {
    $this->{ua}->$method(
      $url,
      UserAgent::Any::Impl::params_to_hash(@{$params}),
      (defined ${$content} ? ${$content} : ()),
      sub ($, $tx) { $cb->(new_response($tx->res)) });
    return;
  };
}

sub call_p {
  my ($this, $method, $url, $params, $content) = &get_call_args;
  return $this->{ua}->${\"${method}_p"}(
    $url,
    UserAgent::Any::Impl::params_to_hash(@{$params}),
    (defined ${$content} ? ${$content} : ())
  )->then(sub ($tx) { new_response($tx->res) });
}

BEGIN { generate_methods() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Impl::MojoUserAgent

=head1 SYNOPSIS

Implementation of L<UserAgent::Any> for the L<Mojo::UserAgent> class.
