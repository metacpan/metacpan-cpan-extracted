package WebService::Braintree::DiscountGateway;
$WebService::Braintree::DiscountGateway::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::Util qw(to_instance_array);

has 'gateway' => (is => 'ro');

sub all {
    my $self = shift;

    my $response = $self->gateway->http->get("/discounts");
    my $attrs = $response->{discounts} || [];
    return to_instance_array($attrs, 'WebService::Braintree::Discount');
}

__PACKAGE__->meta->make_immutable;

1;
__END__
