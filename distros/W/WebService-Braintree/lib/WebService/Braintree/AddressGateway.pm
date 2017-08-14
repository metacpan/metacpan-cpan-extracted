package WebService::Braintree::AddressGateway;
$WebService::Braintree::AddressGateway::VERSION = '0.92';
use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);
use WebService::Braintree::Validations qw(verify_params address_signature);
use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Result;

has 'gateway' => (is => 'ro');

sub create {
    my($self, $params) = @_;
    my $customer_id = delete($params->{'customer_id'});
    confess "ArgumentError" unless verify_params($params, address_signature());
    $self->_make_request("/customers/$customer_id/addresses", "post", {address => $params});
}

sub find {
    my ($self, $customer_id, $address_id) = @_;
    confess "NotFoundError" unless (validate_id($address_id) && validate_id($customer_id));
    $self->_make_request("/customers/$customer_id/addresses/$address_id", "get")->address;
}

sub update {
    my ($self, $customer_id, $address_id, $params) = @_;
    confess "ArgumentError" unless verify_params($params, address_signature());
    $self->_make_request("/customers/$customer_id/addresses/$address_id", "put", {address => $params});
}

sub delete {
    my ($self, $customer_id, $address_id) = @_;
    $self->_make_request("/customers/$customer_id/addresses/$address_id", "delete");
}

__PACKAGE__->meta->make_immutable;
1;

