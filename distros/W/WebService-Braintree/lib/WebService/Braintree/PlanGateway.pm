# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::PlanGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::Util qw(to_instance_array);

has 'gateway' => (is => 'ro');

use WebService::Braintree::_::Plan;

sub all {
    my $self = shift;

    my $response = $self->gateway->http->get("/plans");
    my $attrs = $response->{plans} || [];
    return to_instance_array($attrs, 'WebService::Braintree::_::Plan');
}

__PACKAGE__->meta->make_immutable;

1;
__END__
