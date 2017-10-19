package WebService::Braintree::WebhookNotification;
$WebService::Braintree::WebhookNotification::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use WebService::Braintree::Util qw(is_hashref);

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

use Moose;
extends 'WebService::Braintree::ResultObject';

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

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

=head1 OBJECT METHODS

In addition to the methods provided by the keys returned from Braintree, this
class provides the following methods:

=head2 subscription()

This returns the subscription associated with this notification (if any). This
will be an object of type L<WebService::Braintree::Subscription/>.

=cut

has subscription => (is => 'rw');

=head2 merchant_account()

This returns the merchant account associated with this notification (if any).
This will be an object of type L<WebService::Braintree::MerchantAccount/>.

=cut

has merchant_account => (is => 'rw');

=head2 disbursement()

This returns the disbursement associated with this notification (if any). This
will be an object of type L<WebService::Braintree::Disbursement/>.

=cut

has disbursement => (is => 'rw');

=head2 transaction()

This returns the stransaction associated with this notification (if any). This
will be an object of type L<WebService::Braintree::Transaction/>.

=cut

has transaction => (is => 'rw');

=head2 partner_merchant()

This returns the partner merchant associated with this notification (if any).
This will be an object of type L<WebService::Braintree::PartnerMerchant/>.

=cut

has partner_merchant => (is => 'rw');

=head2 dispute()

This returns the dispute associated with this notification (if any). This
will be an object of type L<WebService::Braintree::Dispute/>.

=cut

has dispute => (is => 'rw');

=head2 errors()

This returns the errors associated with this notification (if any). This
will be an object of type L<WebService::Braintree::ValidationErrorCollection/>.

=cut

has errors => (is => 'rw');

=head2 message()

This returns the message associated with this notification (if any). This will
be a string.

=cut

has message => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;

    my $wrapper_node = $attributes->{subject};

    if (is_hashref($wrapper_node->{api_error_response})) {
        $wrapper_node = $wrapper_node->{api_error_response};
    }

    if (is_hashref($wrapper_node->{subscription})) {
        $self->subscription(WebService::Braintree::Subscription->new($wrapper_node->{subscription}));
    }

    if (is_hashref($wrapper_node->{merchant_account})) {
        $self->merchant_account(WebService::Braintree::MerchantAccount->new($wrapper_node->{merchant_account}));
    }

    if (is_hashref($wrapper_node->{disbursement})) {
        $self->disbursement(WebService::Braintree::Disbursement->new($wrapper_node->{disbursement}));
    }

    if (is_hashref($wrapper_node->{transaction})) {
        $self->transaction(WebService::Braintree::Transaction->new($wrapper_node->{transaction}));
    }

    if (is_hashref($wrapper_node->{partner_merchant})) {
        $self->partner_merchant(WebService::Braintree::PartnerMerchant->new($wrapper_node->{partner_merchant}));
    }

    if (is_hashref($wrapper_node->{dispute})) {
        $self->dispute(WebService::Braintree::Dispute->new($wrapper_node->{dispute}));
    }

    if (is_hashref($wrapper_node->{errors})) {
        $self->errors(WebService::Braintree::ValidationErrorCollection->new($wrapper_node->{errors}));
        $self->message($wrapper_node->{message});
    }

    delete($attributes->{subject});
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
