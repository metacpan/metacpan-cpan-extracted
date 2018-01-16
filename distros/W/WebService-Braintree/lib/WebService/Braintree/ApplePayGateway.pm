package WebService::Braintree::ApplePayGateway;
$WebService::Braintree::ApplePayGateway::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

has 'gateway' => (is => 'ro');

sub registered_domains {
    my $self = shift;
    $self->_make_request("/processing/apple_pay/registered_domains", "get", undef);
}

sub register_domain {
    my ($self, $domain) = @_;
    $self->_make_request("/processing/apple_pay/validate_domains", "post", {url => $domain});
}

sub unregister_domain {
    my ($self, $domain) = @_;
    $self->_make_request("/processing/apple_pay/unregister_domain", "delete", {url => $domain});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
