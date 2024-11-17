package UserAgent::Any::Impl::LwpUserAgent;

use 5.036;

use Carp;
use Moo;
use UserAgent::Any::Impl::Helper 'get_call_args', 'generate_methods', 'new_response';

use namespace::clean;

with 'UserAgent::Any::Impl';

our $VERSION = 0.01;

sub call {
  my ($self, $method, $url, $params, $content) = &get_call_args;
  my $r =
      $self->{ua}->$method($url, @{$params}, (defined ${$content} ? (Content => ${$content}) : ()));
  return new_response($r);
}

sub call_cb ($self, $url, %params) {
  croak 'UserAgent::Any async methods are not implemented with LWP::UserAgent';
}

sub call_p ($self, $url, %params) {
  croak 'UserAgent::Any async methods are not implemented with LWP::UserAgent';
}

BEGIN { generate_methods() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Impl::LwpUserAgent

=head1 SYNOPSIS

Implementation of L<UserAgent::Any> for the L<LWP::UserAgent> class.
