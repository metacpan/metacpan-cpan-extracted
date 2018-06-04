# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::IdealPayment;
$WebService::Braintree::IdealPayment::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::IdealPayment

=head1 PURPOSE

This class finds IdealPayment payment methods.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 find()

This takes a token and returns a L<response|WebService::Braintee::PaymentMethodResult> with the C<< ideal_payment() >> set.

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->ideal_payment->find($token);
}

=head2 sale()

This takes a token and an optional hashref of parameters. This delegates to
L<WebService::Braintree::Transaction/sale>, setting the
C<< payment_method_token >> appropriately and submitting the transaction for
settlement.

=cut

sub sale {
    my ($class, $ideal_payment_id, $params) = @_;
    $class->gateway->transaction->sale({
        %{$params//{}},
        payment_method_nonce => $ideal_payment_id,
        options => { submit_for_settlement => 1 },
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
