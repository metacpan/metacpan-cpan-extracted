# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::DiscountGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::_::Discount;

sub all {
    my $self = shift;
    return $self->_array_request(
        '/discounts', 'discounts', 'WebService::Braintree::_::Discount',
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
