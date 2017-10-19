package WebService::Braintree::Gateway;
$WebService::Braintree::Gateway::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use WebService::Braintree::AddressGateway;
use WebService::Braintree::ClientTokenGateway;
use WebService::Braintree::CreditCardGateway;
use WebService::Braintree::CreditCardVerificationGateway;
use WebService::Braintree::CustomerGateway;
use WebService::Braintree::MerchantAccountGateway;
use WebService::Braintree::PaymentMethodGateway;
use WebService::Braintree::PaymentMethodNonceGateway;
use WebService::Braintree::PayPalAccountGateway;
use WebService::Braintree::PlanGateway;
use WebService::Braintree::SettlementBatchSummaryGateway;
use WebService::Braintree::SubscriptionGateway;
use WebService::Braintree::TransactionGateway;
use WebService::Braintree::TransparentRedirectGateway;
use WebService::Braintree::WebhookNotificationGateway;
use WebService::Braintree::WebhookTestingGateway;

use Moose;

has 'config' => (is => 'ro');

# TODO: Convert this into a loop around a hash.

has 'address' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::AddressGateway->new(gateway => $self);
});

has 'client_token' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::ClientTokenGateway->new(gateway => $self);
});

has 'credit_card' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::CreditCardGateway->new(gateway => $self);
});

has 'credit_card_verification' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::CreditCardVerificationGateway->new(gateway => $self);
});

has 'customer' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::CustomerGateway->new(gateway => $self);
});

has 'merchant_account' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::MerchantAccountGateway->new(gateway => $self);
});

has 'payment_method' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::PaymentMethodGateway->new(gateway => $self);
});

has 'payment_method_nonce' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::PaymentMethodNonceGateway->new(gateway => $self);
});

has 'paypal_account' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::PayPalAccountGateway->new(gateway => $self);
});

has 'plan' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::PlanGateway->new(gateway => $self);
});

has 'settlement_batch_summary' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::SettlementBatchSummaryGateway->new(gateway => $self);
});

has 'subscription' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::SubscriptionGateway->new(gateway => $self);
});

has 'transaction' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::TransactionGateway->new(gateway => $self);
});

has 'transparent_redirect' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::TransparentRedirectGateway->new(gateway => $self);
});

has 'webhook_notification' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::WebhookNotificationGateway->new(gateway => $self);
});

has 'webhook_testing' => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    WebService::Braintree::WebhookTestingGateway->new(gateway => $self);
});

sub http {
    WebService::Braintree::HTTP->new(config => shift->config);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
