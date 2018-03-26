# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::EuropeBankAccountGateway;

use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::PaymentMethodGatewayBase';

use WebService::Braintree::_::EuropeBankAccount;

sub find {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    return $self->_find(europe_bank_account => (
        "/payment_methods/europe_bank_account/${token}", 'get', undef,
    ));
}

__PACKAGE__->meta->make_immutable;

1;
__END__
