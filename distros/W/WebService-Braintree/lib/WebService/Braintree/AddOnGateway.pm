# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::AddOnGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::_::AddOn;

sub all {
    my $self = shift;
    return $self->_array_request(
        '/add_ons', 'add_ons', 'WebService::Braintree::_::AddOn',
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
