# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::PaymentMethodGatewayBase;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);
use Scalar::Util qw(blessed);

use WebService::Braintree::Util qw(validate_id);

sub _create {
    my ($self, @args) = @_;
    my $response = $self->_make_raw_request(@args);
    return $response if blessed($response);
    return $self->_handle_response($response);
}

sub _update {
    my ($self, @args) = @_;
    my $response = $self->_make_raw_request(@args);
    return $response if blessed($response);
    return $self->_handle_response($response);
}

sub _find {
    my ($self, $method, @args) = @_;
    my $response = $self->_make_raw_request(@args);
    return $response if blessed($response);
    return $self->_handle_response($response)->$method;
}

sub _handle_response {
    my ($self, $response) = @_;

    my @keys = keys %{$response // {}};
    confess "Expected payment_method or api_error_response" unless @keys;

    return WebService::Braintree::PaymentMethodResult->new($response);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
