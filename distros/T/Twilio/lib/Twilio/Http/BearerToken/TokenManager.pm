package Twilio::Http::BearerToken::TokenManager;

use 5.016;
use warnings;

use Carp qw(croak);

our $VERSION = '2.002';

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

sub fetch_token {
  my ($self) = @_;
  croak ref($self) . ' must implement fetch_token';
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::BearerToken::TokenManager - Base class for getting OAuth tokens

=head1 SYNOPSIS

  package My::TokenManager;
  use parent 'Twilio::Http::BearerToken::TokenManager';

  sub fetch_token {
    my ($self, $client) = @_;
    return My::Vault->twilio_access_token;
  }

=head1 DESCRIPTION

A token manager gets an access token for
L<Twilio::AuthStrategy::TokenAuthStrategy>. L<Twilio::Http::BearerToken::ApiTokenManager>
asks Twilio for one. Write a subclass to get tokens some other way, and pass it
as C<token_manager> to L<Twilio::CredentialProvider::ClientCredentialProvider>.

=head1 METHODS

=head2 new

  my $token_manager = Twilio::Http::BearerToken::TokenManager->new;

=head2 fetch_token

  my $token = $token_manager->fetch_token($client);

Returns a new access token. C<$client> is the L<Twilio::Rest::Client> that
needs it, or nothing. Subclasses must implement it.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
