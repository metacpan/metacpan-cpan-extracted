# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::PayPalAccount;
$WebService::Braintree::PayPalAccount::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::PayPalAccount

=head1 PURPOSE

This class finds, creates, updates, and deletes PayPal accounts.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 find()

This takes a token and returns the PayPal account (if it exists).

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->paypal_account->find($token);
}

=head2 create()

This takes a hashref of parameters. It will create a PayPal account.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->paypal_account->create($params);
}

=head2 update()

This takes a token and a hashref of parameters. It will update the
corresponding PayPal account (if found) and returns the updated PayPal account.

=cut

sub update {
    my ($class, $token, $params) = @_;
    $class->gateway->paypal_account->update($token, $params);
}

=head2 delete()

This takes a token and deletes the corresponding PayPal account (if found).

=cut

sub delete {
    my ($class, $token) = @_;
    $class->gateway->paypal_account->delete($token);
}

=head2 sale()

This takes a token and a hashref of transaction parameters and creates a sale
with that token.

=cut

sub sale {
    my ($class, $token, $params) = @_;
    $class->gateway->transaction->sale({
        %{$params // {}},
        payment_method_token => $token,
    });
}

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
