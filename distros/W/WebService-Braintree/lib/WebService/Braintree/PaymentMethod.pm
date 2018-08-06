# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::PaymentMethod;
$WebService::Braintree::PaymentMethod::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::PaymentMethod

=head1 PURPOSE

This class creates and finds payment methods.

=cut

use Moo;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 create()

This takes a hashref of parameters and returns the payment method created.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->payment_method->create($params);
}

=head2 update()

This takes a token and a hashref of parameters. It will update the
corresponding payment method (if found) and returns the updated payment method.

=cut

sub update {
    my ($class, $token, $params) = @_;
    $class->gateway->payment_method->update($token, $params);
}

=head2 delete()

This takes a token and an optional hashref of parameters. It will delete the
corresponding payment method (if found).

The optional hashref can contain the following key(s):

=over 4

=item * revoke_all_grants

=back

=cut

sub delete {
    my ($class, $token, $params) = @_;
    $class->gateway->payment_method->delete($token, $params);
}

=head2 grant()

This takes a token and grants the corresponding payment method (if found).

=cut

sub grant {
    my ($class, $token, $params) = @_;
    $class->gateway->payment_method->grant($token, ($params//{}));
}

=head2 revoke()

This takes a token and revokes the corresponding payment method (if found).

=cut

sub revokes {
    my ($class, $token) = @_;
    $class->gateway->payment_method->revokes($token);
}

=head2 find()

This takes a token and returns the payment method (if it exists).

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->payment_method->find($token);
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
