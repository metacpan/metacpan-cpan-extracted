package WebService::Braintree::PayPalAccount;
$WebService::Braintree::PayPalAccount::VERSION = '0.93';
=head1 NAME

WebService::Braintree::PayPalAccount

=head1 PURPOSE

This class finds and updates PayPal accounts.

=cut

use Moose;
extends 'WebService::Braintree::PaymentMethod';

=head1 CLASS METHODS

=head2 find()

This takes a token and returns the PayPal account (if it exists).

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->paypal_account->find($token);
}

=head2 update()

This takes a token and a hashref of parameters. It will update the
corresponding PayPal account (if found) and returns the updated PayPal account.

=cut

sub update {
    my ($class, $token, $params) = @_;
    $class->gateway->paypal_account->update($token, $params);
}

sub gateway {
    WebService::Braintree->configuration->gateway;
}

=head1 OBJECT METHODS

In addition to the methods provided by the keys returned from Braintree, this
class provides the following methods:

=head2 email()

=cut

has email => ( is => 'rw' );

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NOTES

Most of the classes normally used in WebService::Braintree inherit from
L<WebService::Braintree::ResultObject/>. This class, however, inherits from
L<WebService::Braintree::PaymentMethod/>. The primary benefit of this is that
these objects have a C<< token() >> attribute.

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
