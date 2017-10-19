package WebService::Braintree::PaymentMethodNonceGateway;
$WebService::Braintree::PaymentMethodNonceGateway::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::Util qw(validate_id);

has 'gateway' => (is => 'ro');

sub create {
    my ($self, $token) = @_;
    if (!validate_id($token)) {
        confess "NotFoundError";
    }
    my $response = $self->_make_request("/payment_methods/${token}/nonces", 'post');
    return $response;
}

sub find {
    my ($self, $token) = @_;
    if (!validate_id($token)) {
        confess "NotFoundError";
    }

    my $response = $self->_make_request("/payment_method_nonces/" . $token, 'get');
    return $response;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
