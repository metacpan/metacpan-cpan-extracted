# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::DiscountGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::_::Discount;

use WebService::Braintree::Util qw(to_instance_array);

has 'gateway' => (is => 'ro');

sub all {
    my $self = shift;

    my $response = $self->gateway->http->get("/discounts");
    my $attrs = $response->{discounts} || [];
    return to_instance_array($attrs, 'WebService::Braintree::_::Discount');
}

__PACKAGE__->meta->make_immutable;

1;
__END__
