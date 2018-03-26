# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::CustomerGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

use Carp qw(confess);
use WebService::Braintree::Validations qw(verify_params customer_signature);
use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Result;

use WebService::Braintree::_::Customer;
use WebService::Braintree::CustomerSearch;

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
        inflate => [qw/customers customer _::Customer/],
        search => $block->(WebService::Braintree::CustomerSearch->new),
    });
}

sub all {
    my $self = shift;

    return $self->resource_collection({
        ids_url => "/customers/advanced_search_ids",
        obj_url => "/customers/advanced_search",
        inflate => [qw/customers customer _::Customer/],
    });
}

sub transactions {
    my ($self, $customer_id) = @_;

    return $self->resource_collection({
        ids_url => "/customers/${customer_id}/transaction_ids",
        obj_url => "/customers/${customer_id}/transactions",
        inflate => [qw/credit_card_transactions transaction _::Transaction/],
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
