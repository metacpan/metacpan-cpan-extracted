# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Gateway;

use 5.010_001;
use strictures 1;

use Moose;
use Class::Load qw(try_load_class);

has 'config' => (is => 'ro');

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
