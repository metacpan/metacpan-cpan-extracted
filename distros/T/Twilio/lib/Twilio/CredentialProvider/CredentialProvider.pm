package Twilio::CredentialProvider::CredentialProvider;

use 5.016;
use warnings;

use Carp qw(croak);

our $VERSION = '2.002';

sub new {
  my ($class, $auth_type) = @_;
  return bless { auth_type => $auth_type }, $class;
}

sub get_auth_type { return $_[0]{auth_type} }

sub to_auth_strategy {
  my ($self) = @_;
  croak ref($self) . ' must implement to_auth_strategy';
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::CredentialProvider::CredentialProvider - Base class for credentials other than an Auth Token

=head1 DESCRIPTION

A credential provider is set on the client with the C<credential_provider>
option, and authenticates its requests instead of a username and password. See
L<Twilio::CredentialProvider::ClientCredentialProvider>.

=head1 METHODS

=head2 new

  my $provider = Twilio::CredentialProvider::CredentialProvider->new($auth_type);

=head2 get_auth_type

Returns the name given to L</new>, such as C<client-credentials>.

=head2 to_auth_strategy

Returns the L<Twilio::AuthStrategy::AuthStrategy> that authenticates requests.
Subclasses must implement it.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
