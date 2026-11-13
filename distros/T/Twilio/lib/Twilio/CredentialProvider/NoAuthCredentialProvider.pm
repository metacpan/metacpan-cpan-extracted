package Twilio::CredentialProvider::NoAuthCredentialProvider;

use 5.016;
use warnings;

use parent 'Twilio::CredentialProvider::CredentialProvider';

use Twilio::AuthStrategy::NoAuthStrategy;

our $VERSION = '2.001';

sub new {
  my ($class) = @_;
  return $class->SUPER::new('noauth');
}

sub to_auth_strategy {
  return Twilio::AuthStrategy::NoAuthStrategy->new;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::CredentialProvider::NoAuthCredentialProvider - A client that sends no credentials

=head1 DESCRIPTION

A client with this provider sends requests with no C<Authorization> header. It
is how the request for an OAuth token is sent.

=head1 METHODS

=head2 new

  my $provider = Twilio::CredentialProvider::NoAuthCredentialProvider->new;

=head2 to_auth_strategy

Returns a L<Twilio::AuthStrategy::NoAuthStrategy>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
