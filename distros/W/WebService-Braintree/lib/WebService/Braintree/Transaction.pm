package WebService::Braintree::Transaction;
$WebService::Braintree::Transaction::VERSION = '0.91';
use WebService::Braintree::Transaction::CreatedUsing;
use WebService::Braintree::Transaction::EscrowStatus;
use WebService::Braintree::Transaction::Source;
use WebService::Braintree::Transaction::Status;
use WebService::Braintree::Transaction::Type;

use Moose;
extends "WebService::Braintree::ResultObject";


has  subscription => (is => 'rw');
has  disbursement_details => (is => 'rw');
has  paypal_details => (is => 'rw');


sub BUILD {
    my ($self, $attributes) = @_;
    my $sub_objects = { 'disputes' => 'WebService::Braintree::Dispute'};

    $self->subscription(WebService::Braintree::Subscription->new($attributes->{subscription})) if ref($attributes->{subscription}) eq 'HASH';
    delete($attributes->{subscription});

    $self->disbursement_details(WebService::Braintree::DisbursementDetails->new($attributes->{disbursement_details})) if ref($attributes->{disbursement_details}) eq 'HASH';
    delete($attributes->{disbursement_details});

    $self->paypal_details(WebService::Braintree::PayPalDetails->new($attributes->{paypal})) if ref($attributes->{paypal}) eq 'HASH';
    delete($attributes->{paypal});

    $self->setup_sub_objects($self, $attributes, $sub_objects);
    $self->set_attributes_from_hash($self, $attributes);
}

sub sale {
    my ($class, $params) = @_;
    $class->create($params, 'sale');
}

sub credit {
    my ($class, $params) = @_;
    $class->create($params, 'credit');
}

sub submit_for_settlement {
    my ($class, $id, $amount) = @_;
    my $params = {};
    $params->{'amount'} = $amount if $amount;
    $class->gateway->transaction->submit_for_settlement($id, $params);
}

sub void {
    my ($class, $id) = @_;
    $class->gateway->transaction->void($id);
}

sub refund {
    my ($class, $id, $amount) = @_;
    my $params = {};
    $params->{'amount'} = $amount if $amount;
    $class->gateway->transaction->refund($id, $params);
}

sub create {
    my ($class, $params, $type) = @_;
    $params->{'type'} = $type;
    $class->gateway->transaction->create($params);
}

sub find {
    my ($class, $id) = @_;
    $class->gateway->transaction->find($id);
}

sub search {
    my ($class, $block) = @_;
    $class->gateway->transaction->search($block);
}

sub hold_in_escrow {
    my ($class, $id) = @_;
    $class->gateway->transaction->hold_in_escrow($id);
}

sub release_from_escrow {
    my ($class, $id) = @_;
    $class->gateway->transaction->release_from_escrow($id);
}

sub cancel_release {
    my ($class, $id) = @_;
    $class->gateway->transaction->cancel_release($id);
}

sub all {
    my $class = shift;
    $class->gateway->transaction->all;
}

sub clone_transaction {
    my ($class, $id, $params) = @_;
    $class->gateway->transaction->clone_transaction($id, $params);
}

sub gateway {
    WebService::Braintree->configuration->gateway;
}

sub is_disbursed {
    my $self = shift;
    $self->disbursement_details->is_valid();
};

__PACKAGE__->meta->make_immutable;
1;
