package WebService::Braintree::MerchantAccount;
$WebService::Braintree::MerchantAccount::VERSION = '0.94';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::MerchantAccount

=head1 PURPOSE

This class creates, updates, deletes, and finds merchant accounts.

=cut

use WebService::Braintree::MerchantAccount::IndividualDetails;
use WebService::Braintree::MerchantAccount::AddressDetails;
use WebService::Braintree::MerchantAccount::BusinessDetails;
use WebService::Braintree::MerchantAccount::FundingDetails;

use Moose;
extends "WebService::Braintree::ResultObject";

=head2 create()

This takes a hashref of parameters and returns the merchant account created.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->merchant_account->create($params);
}

=head2 find()

This takes a merchant_account_id returns the merchant account (if it exists).

=cut

sub find {
    my ($class, $merchant_account_id) = @_;
    $class->gateway->merchant_account->find($merchant_account_id);
}

=head2 all()

This returns all the merchant accounts.

=cut

sub all {
    my $class = shift;
    $class->gateway->merchant_account->all;
}

=head2 update()

This takes a merchant_account_id and a hashref of parameters. It will update the
corresponding merchant account (if found) and returns the updated merchant
account.

=cut

sub update {
    my ($class, $merchant_account_id, $params) = @_;
    $class->gateway->merchant_account->update($merchant_account_id, $params);
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

{
    package WebService::Braintree::MerchantAccount::Status;
$WebService::Braintree::MerchantAccount::Status::VERSION = '0.94';
use 5.010_001;
    use strictures 1;

    use constant Active => "active";
    use constant Pending => "pending";
    use constant Suspended => "suspended";
}

{
    package WebService::Braintree::MerchantAccount::FundingDestination;
$WebService::Braintree::MerchantAccount::FundingDestination::VERSION = '0.94';
use 5.010_001;
    use strictures 1;

    use constant Bank => "bank";
    use constant Email => "email";
    use constant MobilePhone => "mobile_phone";
}

=head1 OBJECT METHODS

In addition to the methods provided by the keys returned from Braintree, this
class provides the following methods:

=head2 master_merchant_account()

This returns the master merchant account (if it exists). It will be a
L<WebService::Braintree::MerchantAccount> object.

=cut

has master_merchant_account => (is => 'rw');

=head2 individual_details()

This returns the individual details of this merchant account (if they exist). It
will be a L<WebService::Braintree::MerchantAccount::IndividualDetails> object.

=cut

has individual_details => (is => 'rw');

=head2 business_details()

This returns the business details of this merchant account (if they exist). It
will be a L<WebService::Braintree::MerchantAccount::BusinessDetails> object.

=cut

has business_details => (is => 'rw');

=head2 funding_details()

This returns the funding details of this merchant account (if they exist). It
will be a L<WebService::Braintree::MerchantAccount::FundingDetails> object.

=cut

has funding_details => (is => 'rw');

sub BUILD {
    my ($self, $attrs) = @_;

    $self->build_sub_object($attrs,
        method => 'master_merchant_account',
        class  => 'MerchantAccount',
        key    => 'master_merchant_account',
    );

    $self->build_sub_object($attrs,
        method => 'individual_details',
        class  => 'MerchantAccount::IndividualDetails',
        key    => 'individual',
    );

    $self->build_sub_object($attrs,
        method => 'business_details',
        class  => 'MerchantAccount::BusinessDetails',
        key    => 'business',
    );

    $self->build_sub_object($attrs,
        method => 'funding_details',
        class  => 'MerchantAccount::FundingDetails',
        key    => 'funding',
    );

    $self->set_attributes_from_hash($self, $attrs);
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
