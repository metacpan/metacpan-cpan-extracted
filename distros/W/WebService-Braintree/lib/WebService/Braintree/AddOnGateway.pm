# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::AddOnGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::_::AddOn;

use WebService::Braintree::Util qw(to_instance_array);

has 'gateway' => (is => 'ro');

sub all {
    my $self = shift;

    my $response = $self->gateway->http->get("/add_ons");
    my $attrs = $response->{add_ons} || [];
    return to_instance_array($attrs, 'WebService::Braintree::_::AddOn');
}

__PACKAGE__->meta->make_immutable;

1;
__END__
