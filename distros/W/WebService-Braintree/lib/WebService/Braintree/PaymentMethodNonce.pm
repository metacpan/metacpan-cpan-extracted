# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::PaymentMethodNonce;
$WebService::Braintree::PaymentMethodNonce::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::PaymentMethodNonce

=head1 PURPOSE

This class creates and finds payment method nonces.

=head1 EXPLANATION

TODO

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 create()

This method takes a token and creates a payment method nonce.

=cut

sub create {
    my ($class, $token) = @_;
    $class->gateway->payment_method_nonce->create($token);
}

=head2 find()

This method takes a token and finds the related payment method nonce (if any).

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->payment_method_nonce->find($token);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
