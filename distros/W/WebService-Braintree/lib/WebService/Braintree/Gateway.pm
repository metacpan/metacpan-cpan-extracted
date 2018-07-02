# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Gateway;
$WebService::Braintree::Gateway::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Gateway

=head1 PURPOSE

In the class interface, you will not use this class.

In the object interface, this class provides the interface into the API.

=cut

use Moo;
use Class::Load qw(try_load_class);

use WebService::Braintree::HTTP;

has 'config' => (is => 'ro');

=head1 CONSTRUCTION

You can construct this class by passing in either a
L<config/WebService::Braintree::Configuration> object or the parameters
necessary to build a L<config/WebService::Braintree::Configuration> object.

=cut

# Allow this class to be built with either a $config object or parameters to be
# passed into a $config object.
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    # Allow the original BUILDARGS to coerce the arguments for us.
    my $args = $class->$orig(@_);

    if ( !exists $args->{config} ) {
        $args = {
            config => WebService::Braintree::Config->new( $args ),
        };
    }

    return $args;
};

=head1 METHODS

This ojbect provides the following methods. These methods are used to retrieve
the object that will give access to different elements of the Braintree API.

For additional documentation of how to use these objects, please refer to the
object's documentation. For general documentation, please refer to the main
documentation of L<WebService::Braintree>.

=head3 L<add_on/WebService::Braintree::AddOnGateway>

List all plan add-ons.

=head3 L<address/WebService::Braintree::AddressGateway>

Create, update, delete, and find addresses.

=head3 L<apply_pay/WebService::Braintree::ApplePayGateway>

List, register, and unregister ApplePay domains.

=head3 L<client_token/WebService::Braintree::ClientTokenGateway>

Generate client tokens.  These are used for client-side SDKs to take actions.

=head3 L<credit_card/WebService::Braintree::CreditCardGateway>

Create, update, delete, and find credit cards.

=head3 L<credit_card_verification/WebService::Braintree::CreditCardVerificationGateway>

Find and list credit card verifications.

=head3 L<customer/WebService::Braintree::CustomerGateway>

Create, update, delete, and find customers.

=head3 L<discount/WebService::Braintree::DiscountGateway>

List all plan discounts.

=head3 L<dispute/WebService::Braintree::DisputeGateway>

Accept, and find disputes.

=head3 L<document_upload/WebService::Braintree::DocumentUploadGateway>

Manage document uploads.

=head3 L<europe_bank_account/WebService::Braintree::EuropeBankAccountGateway>

Find Europe Bank Accounts.

=head3 L<ideal_payment/WebService::Braintree::IdealPaymentGateway>

Find IdealPayment payment methods.

=head3 L<merchant/WebService::Braintree::MerchantGateway>

Provision merchants from "raw ApplePay".

=head3 L<merchant_account/WebService::Braintree::MerchantAccountGateway>

Create, update, and find merchant accounts.

=head3 L<payment_method/WebService::Braintree::PaymentMethodGateway>

Create, update, delete, and find payment methods.

=head3 L<payment_method_nonce/WebService::Braintree::PaymentMethodNonceGateway>

Create, update, delete, and find payment method nonces.

=head3 L<paypal_account/WebService::Braintree::PayPalAccountGateway>

Find and update PayPal accounts.

=head3 L<plan/WebService::Braintree::PlanGateway>

List all subscription plans.

=head3 L<settlement_batch_summary/WebService::Braintree::SettlementBatchSummaryGateway>

Generate settlement batch summaries.

=head3 L<subscription/WebService::Braintree::SubscriptionGateway>

Create, update, cancel, find, and handle charges for subscriptions.

=head3 L<transaction/WebService::Braintree::TransactionGateway>

Create, manage, and search for transactions.  This is the workhorse class and it
has many methods.

=head3 L<transaction_line_item/WebService::Braintree::TransactionLineItemGateway>

Find all the transaction line-items.

=head3 L<transparent_redirect/WebService::Braintree::TransparentRedirectGateway>

Manage the transparent redirection of ????.

B<NOTE>: This class needs significant help in documentation.

=head3 L<us_bank_account/WebService::Braintree::UsBankAccountGateway>

Find US Bank Accounts.

=head3 L<webhook_notification/WebService::Braintree::WebhookNotificationGateway>

Manage the webhook notiifcations.

B<NOTE>: This class needs significant help in documentation.

=head3 L<webhook_testing/WebService::Braintree::WebhookTestingGateway>

Manage the webhook testing.

B<NOTE>: This class needs significant help in documentation.

=cut

my %gateways = (
    add_on => 'AddOn',
    address => 'Address',
    apple_pay => 'ApplePay',
    client_token => 'ClientToken',
    credit_card => 'CreditCard',
    verification => 'CreditCardVerification',
    customer => 'Customer',
    discount => 'Discount',
    dispute => 'Dispute',
    document_upload => 'DocumentUpload',
    europe_bank_account => 'EuropeBankAccount',
    ideal_payment => 'IdealPayment',
    merchant => 'Merchant',
    merchant_account => 'MerchantAccount',
    payment_method => 'PaymentMethod',
    payment_method_nonce => 'PaymentMethodNonce',
    paypal_account => 'PayPalAccount',
    plan => 'Plan',
    settlement_batch_summary => 'SettlementBatchSummary',
    subscription => 'Subscription',
    transaction => 'Transaction',
    transaction_line_item => 'TransactionLineItem',
    transparent_redirect => 'TransparentRedirect',
    us_bank_account => 'UsBankAccount',
    webhook_notification => 'WebhookNotification',
    webhook_testing => 'WebhookTesting',
);

while (my ($method, $gateway) = each %gateways) {
    my $package = "WebService::Braintree::${gateway}Gateway";

    my ($ok, $error) = try_load_class($package);
    $ok ? $package->import : die $error;

    has $method => (is => 'ro', lazy => 1, default => sub {
        my $self = shift;
        $package->new(gateway => $self);
    });
}

sub http {
    WebService::Braintree::HTTP->new(config => shift->config);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
