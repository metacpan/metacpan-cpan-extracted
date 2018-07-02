# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::WebhookNotification;
$WebService::Braintree::WebhookNotification::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::WebhookNotification

=head1 PURPOSE

This class parses and verifies webhook notifications.

=head1 NOTES

Unlike all other classes, this class does B<NOT> interact with a REST API.
Instead, this takes data you provide it and either parses it into a usable
object or provides a verification of it.

=cut

use WebService::Braintree::WebhookNotification::Kind;

use Moo;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 parse()

This takes a signature and a payload and returns a parsing of the notification
within that payload. The payload is validated against the signature before
parsing.

The return is an object of this class.

=cut

sub parse {
    my ($class, $signature, $payload) = @_;
    $class->gateway->webhook_notification->parse($signature, $payload);
}

=head2 verify()

This takes a challenge and returns a proper response.

=cut

sub verify {
    my ($class, $challenge) = @_;
    $class->gateway->webhook_notification->verify($challenge);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
