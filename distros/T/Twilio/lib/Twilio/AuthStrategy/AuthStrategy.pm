package Twilio::AuthStrategy::AuthStrategy;

use 5.016;
use warnings;

use Carp qw(croak);

our $VERSION = '2.001';

sub new {
  my ($class, $auth_type) = @_;
  return bless { auth_type => $auth_type }, $class;
}

sub get_auth_type { return $_[0]{auth_type} }

sub get_auth_string {
  my ($self) = @_;
  croak ref($self) . ' must implement get_auth_string';
}

sub requires_authentication {
  my ($self) = @_;
  croak ref($self) . ' must implement requires_authentication';
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::AuthStrategy::AuthStrategy - Base class for how a request is authenticated

=head1 DESCRIPTION

A credential provider, such as
L<Twilio::CredentialProvider::ClientCredentialProvider>, returns an auth
strategy, and the client asks it for the C<Authorization> header of each
request. Applications set a provider on the client and don't use strategies
directly.

=head1 METHODS

=head2 new

  my $strategy = Twilio::AuthStrategy::AuthStrategy->new($auth_type);

=head2 get_auth_type

Returns the name given to L</new>, such as C<token>.

=head2 get_auth_string

  my $header = $strategy->get_auth_string($client);

Returns the value of the C<Authorization> header. C<$client> is the
L<Twilio::Rest::Client> making the request. Subclasses must implement it.

=head2 requires_authentication

Returns true when requests need an C<Authorization> header. Subclasses must
implement it.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
