# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::ClientTokenGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);

use WebService::Braintree::Validations qw(
    verify_params
    client_token_signature_with_customer_id
    client_token_signature_without_customer_id
);

sub generate {
    my ($self, $params) = @_;
    if ($params) {
        confess "ArgumentError" unless $self->_conditionally_verify_params($params);
        $params = {client_token => $params};
    }
    my $result = $self->_make_request("/client_token", 'post', $params);
    return $result->{"response"}->{"client_token"}->{"value"};
}


sub _conditionally_verify_params {
    my ($self, $params) = @_;

    if (exists $params->{"customer_id"}) {
        verify_params($params, client_token_signature_with_customer_id);
    } else {
        verify_params($params, client_token_signature_without_customer_id);
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
