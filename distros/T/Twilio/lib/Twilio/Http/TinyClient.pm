package Twilio::Http::TinyClient;

use 5.016;
use warnings;

use parent 'Twilio::Http::Client';

use HTTP::Tiny;

use Twilio::Exceptions::EnvironmentException;
use Twilio::Http::Response;

our $VERSION = '2.002';

my $STATUS_INTERNAL_ERROR = 599;

sub new {
  my ($class, $options) = @_;
  my $self = $class->SUPER::new($options);

  # HTTP::Tiny resends all headers on a redirect, which could hand the Authorization
  # header to another host. PHP's curl client does not follow redirects either.
  $self->{http_tiny} //= HTTP::Tiny->new(verify_SSL => 1, max_redirect => 0);

  return $self;
}

sub send_request {
  my ($self, $request) = @_;

  my $http_tiny = $self->{http_tiny};
  $http_tiny->timeout($request->{timeout});

  my %arguments = (headers => $request->{headers});
  $arguments{content} = $request->{content} if defined $request->{content};

  my $result = $http_tiny->request($request->{method}, $request->{url}, \%arguments);

  if ($result->{status} == $STATUS_INTERNAL_ERROR) {
    Twilio::Exceptions::EnvironmentException->throw($result->{content});
  }

  return Twilio::Http::Response->new($result->{status}, $result->{content}, $result->{headers});
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::TinyClient - Default HTTP transport, based on HTTP::Tiny

=head1 SYNOPSIS

  my $http = Twilio::Http::TinyClient->new({ timeout => 30 });

  my $client = Twilio::Rest::Client->new($sid, $token, { http_client => $http });

=head1 DESCRIPTION

Sends requests with L<HTTP::Tiny>. TLS certificates are always verified, and
redirects are not followed. Proxy settings come from the C<https_proxy> and
C<all_proxy> environment variables.

A failure before Twilio answers, such as a connection or TLS error, throws
L<Twilio::Exceptions::EnvironmentException>.

=head1 METHODS

=head2 new

  my $http = Twilio::Http::TinyClient->new(\%options);

Accepts the options of L<Twilio::Http::Client/new>, plus C<http_tiny> to supply
your own configured L<HTTP::Tiny> object. In that case, TLS verification and
redirects are your responsibility.

=head2 send_request

See L<Twilio::Http::Client/send_request>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
