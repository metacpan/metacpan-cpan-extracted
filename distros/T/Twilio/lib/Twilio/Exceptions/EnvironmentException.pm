package Twilio::Exceptions::EnvironmentException;

use 5.016;
use warnings;

use parent 'Twilio::Exceptions::TwilioException';

our $VERSION = '2.002';

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Exceptions::EnvironmentException - A request never reached a Twilio response

=head1 DESCRIPTION

Thrown when the transport fails before Twilio answers: DNS, connection, TLS or
timeout problems. See L<Twilio::Exceptions::TwilioException> for the methods.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
