package WebService::Braintree::PaymentMethodGateway;
$WebService::Braintree::PaymentMethodGateway::VERSION = '0.94';
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

