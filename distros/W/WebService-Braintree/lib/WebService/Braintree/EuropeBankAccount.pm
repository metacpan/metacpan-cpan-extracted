# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::EuropeBankAccount;
$WebService::Braintree::EuropeBankAccount::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::EuropeBankAccount

=head1 PURPOSE

This class finds Europe Bank Account payment methods.

=cut

use Moo;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 find()

This takes a token and returns a L<response|WebService::Braintee::PaymentMethodResult> with the C<< europe_bank_account() >> set.

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->europe_bank_account->find($token);
}

=head2 sale()

This takes a token and an optional hashref of parameters. This delegates to
L<WebService::Braintree::Transaction/sale>, setting the
C<< payment_method_token >> appropriately and submitting the transaction for
settlement.

=cut

sub sale {
    my ($class, $token, $params) = @_;
    $class->gateway->transaction->sale({
        %{$params//{}},
        payment_method_token => $token,
        options => { submit_for_settlement => 1 },
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
