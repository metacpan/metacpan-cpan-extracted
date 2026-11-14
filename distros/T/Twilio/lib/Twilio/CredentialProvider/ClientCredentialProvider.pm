package Twilio::CredentialProvider::ClientCredentialProvider;

use 5.016;
use warnings;

use parent 'Twilio::CredentialProvider::CredentialProvider';

use Twilio::AuthStrategy::TokenAuthStrategy;
use Twilio::Exceptions::ConfigurationException;
use Twilio::Http::BearerToken::ApiTokenManager;

our $VERSION = '2.002';

sub new {
  my ($class, $options) = @_;
  $options //= {};

  for my $name (qw(client_id client_secret)) {
    next if length($options->{$name} // q{});
    Twilio::Exceptions::ConfigurationException->throw("$name is required");
  }

  my $self = $class->SUPER::new('client-credentials');
  $self->{grant_type}    = 'client_credentials';
  $self->{client_id}     = $options->{client_id};
  $self->{client_secret} = $options->{client_secret};
  $self->{token_manager} = $options->{token_manager} // $class->token_manager_class->new(
    {
      grant_type    => $self->{grant_type},
      client_id     => $self->{client_id},
      client_secret => $self->{client_secret},
    }
  );
  return $self;
}

sub token_manager_class { return 'Twilio::Http::BearerToken::ApiTokenManager' }

# twilio-php returns a new strategy each time, and so asks for a token on every request. One
# strategy per provider keeps the token until it is about to expire, as twilio-python does, and
# clients that share the provider share the token.
sub to_auth_strategy {
  my ($self) = @_;
  $self->{auth_strategy} //= Twilio::AuthStrategy::TokenAuthStrategy->new($self->{token_manager});
  return $self->{auth_strategy};
}

sub get_client_id     { return $_[0]{client_id} }
sub get_token_manager { return $_[0]{token_manager} }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::CredentialProvider::ClientCredentialProvider - OAuth 2.0 client credentials

=head1 SYNOPSIS

  use Twilio::CredentialProvider::ClientCredentialProvider;
  use Twilio::Rest::Client;

  my $client = Twilio::Rest::Client->new(
    undef, undef,
    {
      credential_provider => Twilio::CredentialProvider::ClientCredentialProvider->new({
        client_id     => $client_id,
        client_secret => $client_secret,
      }),
      account_sid => $account_sid,
    }
  );

  my $message = $client->messages->create($to, { from => $from, body => 'Hello' });

=head1 DESCRIPTION

Authenticates requests with an access token from an OAuth app, instead of an
Auth Token or an API key. Create the app in the Twilio Console, under Account
settings, OAuth applications, and choose its scopes there. See
L<https://www.twilio.com/docs/iam/oauth-apps/account-oauth-apps>.

The first request asks Twilio for a token, with the C<client_credentials>
grant. Later requests use the same token until 30 seconds before it expires,
and then a new one is fetched. Clients that share a provider share its token.

Set C<account_sid> on the client to use account resources such as
C<< $client->messages >>: an OAuth app has no username to take it from. The
C<TWILIO_ACCOUNT_SID> environment variable also sets it.

This differs from twilio-php in a few ways:

=over

=item *

The token is kept until it is about to expire. twilio-php asks for a new one
for every request.

=item *

The options are a hash. twilio-php has C<ClientCredentialProviderBuilder>.

=item *

The token request uses the client's own transport and settings, see
L<Twilio::Http::BearerToken::ApiTokenManager/fetch_token>.

=item *

When Twilio refuses the token request, the
L<Twilio::Exceptions::RestException> reaches the caller as it is, with the
HTTP status and Twilio's error code.

=back

=head1 METHODS

=head2 new

  my $provider = Twilio::CredentialProvider::ClientCredentialProvider->new({
    client_id     => $client_id,
    client_secret => $client_secret,
    token_manager => $token_manager,    # optional
  });

C<client_id> and C<client_secret> are required, and it throws
L<Twilio::Exceptions::ConfigurationException> without them. C<token_manager> is
a L<Twilio::Http::BearerToken::TokenManager> that gets tokens some other way;
the default is a L<Twilio::Http::BearerToken::ApiTokenManager>.

=head2 to_auth_strategy

Returns the provider's L<Twilio::AuthStrategy::TokenAuthStrategy>, the same one
each time.

=head2 token_manager_class

Returns the class of the default token manager.

=head2 get_client_id

=head2 get_token_manager

Return what L</new> was given or built.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
