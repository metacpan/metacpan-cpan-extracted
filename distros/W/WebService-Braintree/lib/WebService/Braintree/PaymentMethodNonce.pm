package WebService::Braintree::PaymentMethodNonce;
$WebService::Braintree::PaymentMethodNonce::VERSION = '0.92';
=head1 NAME

WebService::Braintree::PaymentMethodNonce

=head1 PURPOSE

This class creates and finds payment method nonces.

=cut

use Moose;
extends 'WebService::Braintree::ResultObject';

=head1 CLASS METHODS

=head2 create()

This takes a token and returns the payment method nonce created.

=cut

sub create {
    my ($class, $token) = @_;
    $class->gateway->payment_method_nonce->create($token);
}

=head2 find()

This takes a token and returns the payment method nonce (if it exists).

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->payment_method_nonce->find($token);
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

=head1 OBJECT METHODS

UNKNOWN

=cut

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
