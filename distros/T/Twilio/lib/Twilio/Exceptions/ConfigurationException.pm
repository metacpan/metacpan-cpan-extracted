package Twilio::Exceptions::ConfigurationException;

use 5.016;
use warnings;

use parent 'Twilio::Exceptions::TwilioException';

our $VERSION = '2.002';

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Exceptions::ConfigurationException - The client is missing required settings

=head1 DESCRIPTION

Thrown when a request cannot be made because the client has no credentials.
See L<Twilio::Exceptions::TwilioException> for the methods.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
