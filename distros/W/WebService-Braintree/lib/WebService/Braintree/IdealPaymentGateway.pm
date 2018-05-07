# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::IdealPaymentGateway;

use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::PaymentMethodGatewayBase';

use Carp qw(confess);

use WebService::Braintree::Util qw(is_not_empty validate_id);

use WebService::Braintree::_::IdealPayment;

sub find {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    return $self->_find(ideal_payment => (
        "/payment_methods/ideal_payment/${token}", 'get', undef,
    ));
}

__PACKAGE__->meta->make_immutable;

1;
__END__
