# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::PlanGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::_::Plan;

sub all {
    my $self = shift;
    return $self->_array_request(
        '/plans', 'plans', 'WebService::Braintree::_::Plan',
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
