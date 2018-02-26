package WebService::Braintree::IdealPaymentGateway;
$WebService::Braintree::IdealPaymentGateway::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

has 'gateway' => (is => 'ro');

sub find {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    $self->_make_request("/payment_methods/ideal_payments/$token", "get", undef)->ideal_payment;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
