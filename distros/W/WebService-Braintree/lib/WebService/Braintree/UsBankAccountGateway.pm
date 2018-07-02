# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::UsBankAccountGateway;

use 5.010_001;
use strictures 1;

use Moo;
extends 'WebService::Braintree::PaymentMethodGatewayBase';

use Carp qw(confess);

use WebService::Braintree::Util qw(validate_id);

use WebService::Braintree::_::UsBankAccount;

sub find {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    return $self->_find(us_bank_account => (
        "/payment_methods/us_bank_account/${token}", 'get', undef,
    ));
}

__PACKAGE__->meta->make_immutable;

1;
__END__
