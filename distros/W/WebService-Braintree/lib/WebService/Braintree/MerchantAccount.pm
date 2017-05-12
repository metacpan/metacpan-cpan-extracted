package WebService::Braintree::MerchantAccount;
$WebService::Braintree::MerchantAccount::VERSION = '0.9';
use WebService::Braintree::MerchantAccount::IndividualDetails;
use WebService::Braintree::MerchantAccount::AddressDetails;
use WebService::Braintree::MerchantAccount::BusinessDetails;
use WebService::Braintree::MerchantAccount::FundingDetails;

use Moose;
extends "WebService::Braintree::ResultObject";

{
    package WebService::Braintree::MerchantAccount::Status;
$WebService::Braintree::MerchantAccount::Status::VERSION = '0.9';
use constant Active => "active";
    use constant Pending => "pending";
    use constant Suspended => "suspended";
}

{
    package WebService::Braintree::MerchantAccount::FundingDestination;
$WebService::Braintree::MerchantAccount::FundingDestination::VERSION = '0.9';
use constant Bank => "bank";
    use constant Email => "email";
    use constant MobilePhone => "mobile_phone";
}

has  master_merchant_account => (is => 'rw');
has  individual_details => (is => 'rw');
has  business_details => (is => 'rw');
has  funding_details => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;

    $self->master_merchant_account(WebService::Braintree::MerchantAccount->new($attributes->{master_merchant_account})) if ref($attributes->{master_merchant_account}) eq 'HASH';
    delete($attributes->{master_merchant_account});


    $self->individual_details(WebService::Braintree::MerchantAccount::IndividualDetails->new($attributes->{individual})) if ref($attributes->{individual}) eq 'HASH';
    delete($attributes->{individual});


    $self->business_details(WebService::Braintree::MerchantAccount::BusinessDetails->new($attributes->{business})) if ref($attributes->{business}) eq 'HASH';
    delete($attributes->{business});


    $self->funding_details(WebService::Braintree::MerchantAccount::FundingDetails->new($attributes->{funding})) if ref($attributes->{funding}) eq 'HASH';
    delete($attributes->{funding});

    $self->set_attributes_from_hash($self, $attributes);
}

sub create {
    my ($class, $params) = @_;
    $class->gateway->merchant_account->create($params);
}

sub update {
    my ($class, $merchant_account_id, $params) = @_;
    $class->gateway->merchant_account->update($merchant_account_id, $params);
}

sub find {
    my ($class, $merchant_account_id) = @_;
    $class->gateway->merchant_account->find($merchant_account_id);
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

__PACKAGE__->meta->make_immutable;
1;
