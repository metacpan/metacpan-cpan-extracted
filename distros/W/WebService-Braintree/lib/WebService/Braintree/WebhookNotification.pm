package WebService::Braintree::WebhookNotification;
$WebService::Braintree::WebhookNotification::VERSION = '0.91';

use WebService::Braintree::WebhookNotification::Kind;
use Moose;

extends 'WebService::Braintree::ResultObject';

has  subscription => (is => 'rw');
has  merchant_account => (is => 'rw');
has  disbursement => (is => 'rw');
has  transaction => (is => 'rw');
has  partner_merchant => (is => 'rw');
has  dispute => (is => 'rw');
has  errors => (is => 'rw');
has  message => (is => 'rw');


sub BUILD {
    my ($self, $attributes) = @_;

    my $wrapper_node = $attributes->{subject};

    if (ref($wrapper_node->{api_error_response}) eq 'HASH') {
        $wrapper_node = $wrapper_node->{api_error_response};
    }

    if (ref($wrapper_node->{subscription}) eq 'HASH') {

        $self->subscription(WebService::Braintree::Subscription->new($wrapper_node->{subscription}));
    }

    if (ref($wrapper_node->{merchant_account}) eq 'HASH') {

        $self->merchant_account(WebService::Braintree::MerchantAccount->new($wrapper_node->{merchant_account}));
    }

    if (ref($wrapper_node->{disbursement}) eq 'HASH') {

        $self->disbursement(WebService::Braintree::Disbursement->new($wrapper_node->{disbursement}));
    }

    if (ref($wrapper_node->{transaction}) eq 'HASH') {

        $self->transaction(WebService::Braintree::Transaction->new($wrapper_node->{transaction}));
    }

    if (ref($wrapper_node->{partner_merchant}) eq 'HASH') {

        $self->partner_merchant(WebService::Braintree::PartnerMerchant->new($wrapper_node->{partner_merchant}));
    }

    if (ref($wrapper_node->{dispute}) eq 'HASH') {

        $self->dispute(WebService::Braintree::Dispute->new($wrapper_node->{dispute}));
    }

    if (ref($wrapper_node->{errors}) eq 'HASH') {
        $self->errors(WebService::Braintree::ValidationErrorCollection->new($wrapper_node->{errors}));
        $self->message($wrapper_node->{message});
    }

    delete($attributes->{subject});
    $self->set_attributes_from_hash($self, $attributes);
}

sub parse {
    my ($class, $signature, $payload) = @_;
    $class->gateway->webhook_notification->parse($signature, $payload);
}

sub verify {
    my ($class, $params) = @_;
    $class->gateway->webhook_notification->verify($params);
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

__PACKAGE__->meta->make_immutable;
1;
