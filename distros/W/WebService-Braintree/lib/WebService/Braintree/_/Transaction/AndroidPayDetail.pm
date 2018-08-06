# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::AndroidPayDetail;
$WebService::Braintree::_::Transaction::AndroidPayDetail::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::AndroidPayDetail

=head1 PURPOSE

This class represents a transaction AndroidPay detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 expiration_month()

This is the expiration month for this transaction ApplePay detail.

=cut

has expiration_month => (
    is => 'ro',
);

=head2 expiration_year()

This is the expiration year for this transaction ApplePay detail.

=cut

has expiration_year => (
    is => 'ro',
);
=head2 google_transaction_id()

This is the Google transaction id for this transaction AndroidPay checkout detail.

=cut

has google_transaction_id => (
    is => 'ro',
);

=head2 source_card_last_4()

This is the source card last_4 for this transaction AndroidPay checkout detail.

=cut

has source_card_last_4 => (
    is => 'ro',
);

=head2 source_card_type()

This is the source card type for this transaction AndroidPay checkout detail.

=cut

has source_card_type => (
    is => 'ro',
);

=head2 source_description()

This is the source description for this transaction AndroidPay checkout detail.

=cut

has source_description => (
    is => 'ro',
);

=head2 virtual_card_last_4()

This is the virtual card last_4 for this transaction AndroidPay checkout detail.

C<< last_4() >> is an alias to this attribute.

=cut

has virtual_card_last_4 => (
    is => 'ro',
    alias => 'last_4',
);

=head2 virtual_card_type()

This is the virtual card type for this transaction AndroidPay checkout detail.

C<< card_type() >> is an alias to this attribute.

=cut

has virtual_card_type => (
    is => 'ro',
    alias => 'card_type',
);

=head1 METHODS

=head2 expiration_date()

This returns the expiration date in MM/YYYY format.

=cut

sub expiration_date {
    my $self = shift;
    $self->expiration_month . '/' . $self->expiration_year;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
