# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::TransactionGateway;

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

use WebService::Braintree::_::Transaction;
use WebService::Braintree::TransactionSearch;

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
    my ($self, $id, $amount) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->create({
        subscription_id => $id,
        amount => $amount,
        type => "sale"
    });
}

sub submit_for_settlement {
    my ($self, $id, $params) = @_;

    confess "NotFoundError" unless validate_id($id);
    confess "ArgumentError" unless verify_params($params, {
        order_id => 1,
        description => {
            name => 1,
            phone => 1,
            url => 1,
        },
    });

    $self->_make_request("/transactions/$id/submit_for_settlement", "put", {transaction => $params});
}

sub void {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/transactions/$id/void", "put", undef);
}

sub refund {
    my ($self, $id, $params) = @_;

    confess "NotFoundError" unless validate_id($id);
    confess "ArgumentError" unless verify_params($params, {
        amount => 1,
        order_id => 1,
    });

    $self->_make_request("/transactions/$id/refund", "post", {transaction => $params});
}

sub clone_transaction {
    my ($self, $id, $params) = @_;
    confess "NotFoundError" unless validate_id($id);
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
        inflate => [qw/credit_card_transactions transaction _::Transaction/],
        search => $block->(WebService::Braintree::TransactionSearch->new),
    });
}

sub hold_in_escrow {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/transactions/$id/hold_in_escrow", "put", undef);
}

sub release_from_escrow {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/transactions/$id/release_from_escrow", "put", undef);
}

sub cancel_release {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/transactions/$id/cancel_release", "put", undef);
}

sub update_details {
    my ($self, $id, $params) = @_;

    confess "NotFoundError" unless validate_id($id);
    confess "ArgumentError" unless verify_params($params, {
        amount => 1,
        order_id => 1,
        description => {
            name => 1,
            phone => 1,
            url => 1,
        },
    });

    $self->_make_request("/transactions/$id/update_details", "put", { transaction => $params });
}

sub submit_for_partial_settlement {
    my ($self, $id, $amount, $params) = @_;

    confess "NotFoundError" unless validate_id($id);
    confess "ArgumentError" unless verify_params($params, {
        order_id => 1,
        description => {
            name => 1,
            phone => 1,
            url => 1,
        },
    });

    $self->_make_request("/transactions/$id/submit_for_partial_settlement", "post", { transaction => {%$params, amount => $amount}});
}

sub all {
    my $self = shift;

    return $self->resource_collection({
        ids_url => "/transactions/advanced_search_ids",
        obj_url => "/transactions/advanced_search",
        inflate => [qw/credit_card_transactions transaction _::Transaction/],
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
