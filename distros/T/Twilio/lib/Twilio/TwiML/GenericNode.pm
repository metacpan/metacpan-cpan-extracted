package Twilio::TwiML::GenericNode;

use 5.016;
use warnings;

use parent 'Twilio::TwiML::TwiML';

our $VERSION = '2.002';

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::TwiML::GenericNode - A TwiML element with any name

=head1 SYNOPSIS

  my $child = $response->add_child('NewVerb', 'text', { option => 'value' });

=head1 DESCRIPTION

Returned by L<Twilio::TwiML::TwiML/add_child>, for TwiML this library does not
know about yet. See L<Twilio::TwiML::TwiML> for its methods.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
