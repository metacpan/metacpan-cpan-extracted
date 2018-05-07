# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::ApplePayGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);

use WebService::Braintree::Util qw(validate_id);

use WebService::Braintree::_::ApplePay;

sub registered_domains {
    my $self = shift;
    $self->_make_request("/processing/apple_pay/registered_domains", "get", undef);
}

sub register_domain {
    my ($self, $domain) = @_;
    confess "NotFoundError" unless validate_id($domain);
    $self->_make_request("/processing/apple_pay/validate_domains", "post", {url => $domain});
}

sub unregister_domain {
    my ($self, $domain) = @_;
    confess "NotFoundError" unless validate_id($domain);
    $self->_make_request("/processing/apple_pay/unregister_domain", "delete", {url => $domain});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
