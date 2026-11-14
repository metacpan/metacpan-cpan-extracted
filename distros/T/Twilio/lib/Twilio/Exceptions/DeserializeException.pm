package Twilio::Exceptions::DeserializeException;

use 5.016;
use warnings;

use parent 'Twilio::Exceptions::TwilioException';

our $VERSION = '2.002';

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Exceptions::DeserializeException - A response could not be understood

=head1 DESCRIPTION

Thrown when a page of results has no recognisable list of records. See
L<Twilio::Exceptions::TwilioException> for the methods.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
