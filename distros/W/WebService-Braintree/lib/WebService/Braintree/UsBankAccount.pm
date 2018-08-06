# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::UsBankAccount;
$WebService::Braintree::UsBankAccount::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::UsBankAccount

=head1 PURPOSE

This class finds US Bank Account payment methods.

=cut

use Moo;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 find()

This takes a token and returns the US Bank account (if it exists).

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->us_bank_account->find($token);
}

=head2 sale()

This takes a token and an optional hashref of parameters and creates a sale
transaction on the provided token.

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
