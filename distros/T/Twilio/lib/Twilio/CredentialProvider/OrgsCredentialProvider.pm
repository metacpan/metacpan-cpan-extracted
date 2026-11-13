package Twilio::CredentialProvider::OrgsCredentialProvider;

use 5.016;
use warnings;

use parent 'Twilio::CredentialProvider::ClientCredentialProvider';

use Twilio::Http::BearerToken::OrgsTokenManager;

our $VERSION = '2.001';

sub token_manager_class { return 'Twilio::Http::BearerToken::OrgsTokenManager' }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::CredentialProvider::OrgsCredentialProvider - OAuth 2.0 client credentials of an Organization app

=head1 SYNOPSIS

  my $client = Twilio::Rest::Client->new(
    undef, undef,
    {
      credential_provider => Twilio::CredentialProvider::OrgsCredentialProvider->new({
        client_id     => $client_id,
        client_secret => $client_secret,
      }),
    }
  );

  my $organization = $client->preview_iam->versionless->organization($organization_sid);
  for my $user ($organization->users->read) {
    ...
  }

=head1 DESCRIPTION

For an OAuth app created under Organization settings, to use the Organization
APIs. It works as L<Twilio::CredentialProvider::ClientCredentialProvider> does,
with a L<Twilio::Http::BearerToken::OrgsTokenManager>, as in twilio-php and
twilio-python.

=head1 METHODS

=head2 token_manager_class

Returns C<Twilio::Http::BearerToken::OrgsTokenManager>. The other methods are
those of L<Twilio::CredentialProvider::ClientCredentialProvider>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
