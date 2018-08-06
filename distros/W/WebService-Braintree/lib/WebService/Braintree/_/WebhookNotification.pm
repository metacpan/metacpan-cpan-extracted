# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::WebhookNotification;
$WebService::Braintree::_::WebhookNotification::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::WebhookNotification

=head1 PURPOSE

This class represents a webhook notification.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::Types qw(
    ErrorResult
    HashInflator
    AccountUpdaterDailyReport
    ConnectedMerchantPayPalStatusChanged
    ConnectedMerchantStatusTransitioned
    Disbursement
    Dispute
    GrantedPaymentInstrumentUpdate
    IdealPayment
    MerchantAccount
    Subscription
    Transaction
);

=head1 ATTRIBUTES

=cut

=head2 account_updater_daily_report()

This returns the webhook notification's account-updater daily report.

=cut

has account_updater_daily_report => (
    is => 'rw',
);

=head2 api_error_response()

This returns the webhook notification's API error response. This will be an object of type
L<WebService::Braintree::ErrorResult/>.

C<< error_result() >> is an alias for this attribute.

=cut

has api_error_response => (
    is => 'rw',
    isa => ErrorResult,
    coerce => 1,
    alias => 'error_result',
);

=head2 connected_merchant_paypal_status_changed()

This returns the webhook notification's status change of the connected merchant. This will be an object of type
L<WebService::Braintree::_::ConnectedMerchantPayPalStatusChanged/>.

=cut

has connected_merchant_paypal_status_changed => (
    is => 'rw',
    isa => ConnectedMerchantPayPalStatusChanged,
    coerce => 1,
);

=head2 connected_merchant_status_transmitted()

This returns the webhook notification's status transition of connected merchant. This will be an object of type
L<WebService::Braintree::_::ConnectedMerchantstatusTransitioned/>.

=cut

has connected_merchant_status_transitioned => (
    is => 'rw',
    isa => ConnectedMerchantStatusTransitioned,
    coerce => 1,
);

=head2 disbursement()

This returns the webhook notification's disbursement. This will be an object of type
L<WebService::Braintree::_::Disbursement/>.

=cut

has disbursement => (
    is => 'rw',
    isa => Disbursement,
    coerce => 1,
);

=head2 dispute()

This returns the webhook notification's dispute. This will be an object of type
L<WebService::Braintree::_::Dispute/>.

=cut

has dispute => (
    is => 'rw',
    isa => Dispute,
    coerce => 1,
);

=head2 granted_payment_instrument_type()

This returns the webhook notification's granted payment instrument type. This will be an object of type
L<WebService::Braintree::_::GrantedPaymentInstrumentUpdate/>.

=cut

has granted_payment_instrument_update => (
    is => 'rw',
    isa => GrantedPaymentInstrumentUpdate,
    coerce => 1,
);

=head2 ideal_payment()

This returns the webhook notification's Ideal payment. This will be an object of type
L<WebService::Braintree::_::IdealPayment/>.

=cut

has ideal_payment => (
    is => 'rw',
    isa => IdealPayment,
    coerce => 1,
);

=head2 kind()

This returns the webhook notification's kind.

=cut

has kind => (
    is => 'rw',
);

=head2 merchant_account()

This returns the webhook notification's merchant account. This will be an object of type
L<WebService::Braintree::_::MerchantAccount/>.

=cut

has merchant_account => (
    is => 'rw',
    isa => MerchantAccount,
    coerce => 1,
);

=head2 partner_merchant()

This returns the webhook notification's partner merchant. This will be an object of type
L<Hash::Inflator/>.

=cut

has partner_merchant => (
    is => 'rw',
    isa => HashInflator,
    coerce => 1,
);

=head2 subscription()

This returns the webhook notification's subscription. This will be an object of type
L<WebService::Braintree::_::Subscription/>.

=cut

has subscription => (
    is => 'rw',
    isa => Subscription,
    coerce => 1,
);

=head2 subject()

This returns the webhook notification's subject.

This is not meant for client usage.

=cut

has subject => (
    is => 'rw',
);

=head2 timestamp()

This returns the webhook notification's timestamp.

=cut

has timestamp => (
    is => 'rw',
);

=head2 transaction()

This returns the webhook notification's transaction. This will be an object of type
L<WebService::Braintree::_::Transaction/>.

=cut

has transaction => (
    is => 'rw',
    isa => Transaction,
    coerce => 1,
);

# WebhookNotification receives a single parameter called 'subject'.
# Everything we care about is on that. So, let the parent's BUILD set
# the subject(), then we assign the rest of the attributes from there.
#
# Note: This means the attributes need to be rw instead of ro.
sub BUILD {
    my $self = shift;

    my $wrapper = $self->subject;
    if (exists $wrapper->{api_error_response}) {
        $self->api_error_response($wrapper->{api_error_response});
        $wrapper = $wrapper->{api_error_response};
    }

    # Yes, this is a duplicate list of the attributes and could be
    # retrieved with $self->meta->get_all_attributes(). But, we use
    # Moo, not Moose, so there's no $self->meta.
    foreach my $attr (qw(
        account_updater_daily_report
        api_error_response
        connected_merchant_paypal_status_changed
        connected_merchant_status_transitioned
        disbursement
        dispute
        granted_payment_instrument_update
        ideal_payment
        kind
        merchant_account
        partner_merchant
        subscription
        subject
        timestamp
        transaction
    )) {
        next unless exists $wrapper->{$attr};

        $self->$attr($wrapper->{$attr});
    }
}

=head1 METHODS

=cut

# TODO: Delegate merchant_account() to error_result() if it's set.

=head2 errors

This returns the errors if this object has errors.

=cut

sub errors {
    my $self = shift;
    return $self->error_result->errors if $self->error_result;
    return;
}

=head2 message

This returns the error's message if this object has errors.

=cut

sub message {
    my $self = shift;
    return $self->error_result->message if $self->error_result;
    return;
}

=head2 is_check

This returns true if this is a check.

=cut

sub is_check {
    my $self = shift;
    return !!$self->subject->{check};
}

__PACKAGE__->meta->make_immutable;

1;
__END__
