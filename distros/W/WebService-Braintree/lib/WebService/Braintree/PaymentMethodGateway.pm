package WebService::Braintree::PaymentMethodGateway;
$WebService::Braintree::PaymentMethodGateway::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);

has 'gateway' => (is => 'ro');

use WebService::Braintree::Util qw(validate_id);

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

sub grant {
    my ($self, $token, $params) = @_;
    $self->_make_request("/payment_methods/grant", 'post', {payment_method => { %$params, shared_payment_method_token => $token}});
}

sub revoke {
    my ($self, $token) = @_;
    $self->_make_request("/payment_methods/revoke", 'post', {payment_method => { shared_payment_method_token => $token}});
}

sub find {
    my ($self, $token) = @_;
    if (!validate_id($token)) {
        confess "NotFoundError";
    }

    my $response = $self->_make_request("/payment_methods/any/" . $token, 'get');
    return $response->payment_method;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

