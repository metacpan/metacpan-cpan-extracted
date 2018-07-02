# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::EuropeBankAccountGateway;

use 5.010_001;
use strictures 1;

use Moo;
extends 'WebService::Braintree::PaymentMethodGatewayBase';

use Carp qw(confess);

use WebService::Braintree::Util qw(is_not_empty validate_id);

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
