package WebService::Braintree::CustomerGateway;
$WebService::Braintree::CustomerGateway::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

use Carp qw(confess);
use WebService::Braintree::Validations qw(verify_params customer_signature);
use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Result;

has 'gateway' => (is => 'ro');

sub create {
    my ($self, $params) = @_;
    confess "ArgumentError" unless verify_params($params, customer_signature);
    $self->_make_request("/customers/", 'post', { customer => $params });
}

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/customers/$id", 'get', undef)->customer;
}

sub delete {
    my ($self, $id) = @_;
    $self->_make_request("/customers/$id", "delete", undef);
}

sub update {
    my ($self, $id, $params) = @_;
    confess "ArgumentError" unless verify_params($params, customer_signature);
    $self->_make_request("/customers/$id", 'put', {customer => $params});
}

sub search {
    my ($self, $block) = @_;

    return $self->resource_collection({
        ids_url => "/customers/advanced_search_ids",
        obj_url => "/customers/advanced_search",
        inflate => [qw/customers customer Customer/],
        search => $block->(WebService::Braintree::CustomerSearch->new),
    });
}

sub all {
    my $self = shift;

    return $self->resource_collection({
        ids_url => "/customers/advanced_search_ids",
        obj_url => "/customers/advanced_search",
        inflate => [qw/customers customer Customer/],
    });
}

sub transactions {
    my ($self, $customer_id) = @_;

    return $self->resource_collection({
        ids_url => "/customers/${customer_id}/transaction_ids",
        obj_url => "/customers/${customer_id}/transactions",
        inflate => [qw/credit_card_transactions transaction Transaction/],
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
