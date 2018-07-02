# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::MerchantGateway;

use 5.010_001;
use strictures 1;

use Moo;
with 'WebService::Braintree::Role::MakeRequest';

use WebService::Braintree::_::Merchant;

sub provision_raw_apple_pay {
    my $self = shift;
    $self->_make_request("/provision_raw_apply_pay", "put", undef);
}

# This is in the Ruby SDK in the MerchantGateway class for use within the
# tests, but it returns a 404 when I tried it against my sandbox. I am leaving
# it in here until I figure out why this doesn't work.
#sub create {
#    my ($self, $params) = @_;
#    $self->_make_request("/merchants/create_via_api", "post", {merchant => $params});
#}

__PACKAGE__->meta->make_immutable;

1;
__END__
