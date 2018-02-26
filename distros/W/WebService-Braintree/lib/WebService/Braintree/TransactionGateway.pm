package WebService::Braintree::TransactionGateway;
$WebService::Braintree::TransactionGateway::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

use Carp qw(confess);
use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Validations qw(
    verify_params transaction_signature clone_transaction_signature
    transaction_search_results_signature
);

has 'gateway' => (is => 'ro');

sub create {
    my ($self, $params) = @_;
    confess "ArgumentError" unless verify_params($params, transaction_signature);
    $self->_make_request("/transactions/", "post", {transaction => $params});
}

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/transactions/$id", "get", undef);
}

sub retry_subscription_charge {
    my ($self, $subscription_id, $amount) = @_;
    my $params = {
        subscription_id => $subscription_id,
        amount => $amount,
        type => "sale"
    };

    $self->create($params);
}

sub submit_for_settlement {
    my ($self, $id, $params) = @_;
    $self->_make_request("/transactions/$id/submit_for_settlement", "put", {transaction => $params});
}

sub void {
    my ($self, $id) = @_;
    $self->_make_request("/transactions/$id/void", "put", undef);
}

sub refund {
    my ($self, $id, $params) = @_;
    $self->_make_request("/transactions/$id/refund", "post", {transaction => $params});
}

sub clone_transaction {
    my ($self, $id, $params) = @_;
    confess "ArgumentError" unless verify_params($params, clone_transaction_signature);
    $self->_make_request("/transactions/$id/clone", "post", {transaction_clone => $params});
}

sub search {
    my ($self, $block) = @_;

    return $self->resource_collection({
        ids_url => "/transactions/advanced_search_ids",
        post_ids => sub {
            my $response = shift;
            confess "DownForMaintenanceError" unless
                verify_params($response, transaction_search_results_signature);
        },
        obj_url => "/transactions/advanced_search",
        inflate => [qw/credit_card_transactions transaction Transaction/],
        search => $block->(WebService::Braintree::TransactionSearch->new),
    });
}

sub hold_in_escrow {
    my ($self, $id) = @_;
    $self->_make_request("/transactions/$id/hold_in_escrow", "put", undef);
}

sub release_from_escrow {
    my ($self, $id) = @_;
    $self->_make_request("/transactions/$id/release_from_escrow", "put", undef);
}

sub cancel_release {
    my ($self, $id) = @_;
    $self->_make_request("/transactions/$id/cancel_release", "put", undef);
}

sub update_details {
    my ($self, $id, $params) = @_;
    $self->_make_request("/transactions/$id/update_details", "put", { transaction => $params });
}

sub submit_for_partial_settlement {
    my ($self, $id, $amount, $params) = @_;
    $self->_make_request("/transactions/$id/submit_for_partial_settlement", "post", { transaction => {%$params, amount => $amount}});
}

sub all {
    my $self = shift;

    return $self->resource_collection({
        ids_url => "/transactions/advanced_search_ids",
        obj_url => "/transactions/advanced_search",
        inflate => [qw/credit_card_transactions transaction Transaction/],
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
