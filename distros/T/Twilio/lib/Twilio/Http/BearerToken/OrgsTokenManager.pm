package Twilio::Http::BearerToken::OrgsTokenManager;

use 5.016;
use warnings;

use parent 'Twilio::Http::BearerToken::ApiTokenManager';

our $VERSION = '2.001';

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::BearerToken::OrgsTokenManager - Gets OAuth tokens for an Organization app

=head1 DESCRIPTION

Used by L<Twilio::CredentialProvider::OrgsCredentialProvider>. It works as
L<Twilio::Http::BearerToken::ApiTokenManager> does: twilio-php and
twilio-python also ask the same endpoint for both, and keep the two names so
code can say which kind of app it uses.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
