package WebService::Braintree::PaymentMethodGateway;
$WebService::Braintree::PaymentMethodGateway::VERSION = '0.92';
use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);

has 'gateway' => (is => 'ro');

sub create {
    my ($self, $params) = @_;
    $self->_make_request("/payment_methods", 'post', {payment_method => $params});
}

sub update {
    my ($self, $token, $params) = @_;
    $self->_make_request("/payment_methods/any/" . $token, "put", {payment_method => $params});
}

sub delete {
    my ($self, $token) = @_;
    $self->_make_request("/payment_methods/any/" . $token, 'delete');
}

sub find {
    my ($self, $token) = @_;
    if (!defined($token) || WebService::Braintree::Util::trim($token) eq "") {
        confess "NotFoundError";
    }

    my $response = $self->_make_request("/payment_methods/any/" . $token, 'get');
    return $response->payment_method;
}


__PACKAGE__->meta->make_immutable;
1;

