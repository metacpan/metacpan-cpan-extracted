package Twilio::Http::BearerToken::ApiTokenManager;

use 5.016;
use warnings;

use parent 'Twilio::Http::BearerToken::TokenManager';

use Twilio::CredentialProvider::NoAuthCredentialProvider;
use Twilio::Exceptions::TwilioException;

our $VERSION = '2.002';

my @TOKEN_OPTIONS = qw(client_id client_secret code redirect_uri audience refresh_token scope);

sub new {
  my ($class, $options) = @_;
  $options //= {};
  my $self = $class->SUPER::new;
  $self->{grant_type} = $options->{grant_type} // 'client_credentials';
  $self->{$_} = $options->{$_} for @TOKEN_OPTIONS;
  return $self;
}

sub fetch_token {
  my ($self, $client) = @_;

  my $token = $self->_token_client($client)
    ->oauth->v2->token->create($self->{grant_type}, { map { $_ => $self->{$_} } @TOKEN_OPTIONS });
  my $access_token = $token->access_token;
  if (!defined $access_token || !length $access_token) {
    Twilio::Exceptions::TwilioException->throw('Twilio answered with no OAuth access token');
  }
  return $access_token;
}

# The token request carries no credentials, so its client has none, and it can't ask for a
# token itself. Unlike twilio-php, it goes through the caller's transport and settings, so a
# proxy, a custom transport, an edge or a fake client in tests applies to it too.
sub _token_client {
  my ($self, $client) = @_;

  require Twilio::Rest::Client;
  my %options = (credential_provider => Twilio::CredentialProvider::NoAuthCredentialProvider->new);
  return Twilio::Rest::Client->new(undef, undef, \%options) if !$client;

  my $token_client = Twilio::Rest::Client->new(
    undef, undef,
    {
      %options,
      environment => $client->get_environment,
      http_client => $client->get_http_client,
      region      => $client->get_region,
      edge        => $client->get_edge,
      max_retries => $client->get_max_retries,
    }
  );
  $token_client->set_log_level($client->get_log_level);
  return $token_client;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::BearerToken::ApiTokenManager - Gets OAuth tokens from Twilio

=head1 DESCRIPTION

Used by L<Twilio::CredentialProvider::ClientCredentialProvider>. It asks
C<https://oauth.twilio.com/v2/token> for an access token, with
C<< $client->oauth->v2->token->create >>.

=head1 METHODS

=head2 new

  my $token_manager = Twilio::Http::BearerToken::ApiTokenManager->new({
    grant_type    => 'client_credentials',
    client_id     => $client_id,
    client_secret => $client_secret,
  });

C<grant_type> defaults to C<client_credentials>. The other options, all sent
as given, are C<client_id>, C<client_secret>, C<code>, C<redirect_uri>,
C<audience>, C<refresh_token> and C<scope>.

=head2 fetch_token

  my $token = $token_manager->fetch_token($client);

Returns a new access token. The request has no credentials besides the
options, and uses the transport, edge, region, retries and log level of
C<$client>. With no C<$client>, it uses a new L<Twilio::Rest::Client> with the
defaults.

It throws L<Twilio::Exceptions::RestException> when Twilio refuses the request,
and L<Twilio::Exceptions::TwilioException> when the answer has no token.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
