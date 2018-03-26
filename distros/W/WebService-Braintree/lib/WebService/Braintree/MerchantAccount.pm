# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::MerchantAccount;
$WebService::Braintree::MerchantAccount::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::MerchantAccount

=head1 PURPOSE

This class creates, updates, deletes, and finds merchant accounts.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head2 create()

This takes a hashref of parameters and returns a L<response|WebService::Braintee::Result> with the C<< merchant_account() >> set.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->merchant_account->create($params);
}

=head2 find()

This takes a merchant_account_id and returns a L<response|WebService::Braintee::Result> with
the C<< merchant_account() >> set (if found).

=cut

sub find {
    my ($class, $merchant_account_id) = @_;
    $class->gateway->merchant_account->find($merchant_account_id);
}

=head2 all()

This returns a L<collection|WebService::Braintree::PaginatedCollection> of all
L<merchant accounts|WebService::Braintree::_::MerchantAccount>.

=cut

sub all {
    my $class = shift;
    $class->gateway->merchant_account->all;
}

=head2 update()

This takes a merchant_account_id and a hashref of parameters. It will update the corresponding
merchant account (if found) and return a L<response|WebService::Braintee::Result>
with the C<< merchant_account() >> set.

=cut

sub update {
    my ($class, $merchant_account_id, $params) = @_;
    $class->gateway->merchant_account->update($merchant_account_id, $params);
}

{
    package WebService::Braintree::MerchantAccount::Status;
$WebService::Braintree::MerchantAccount::Status::VERSION = '1.2';
use 5.010_001;
    use strictures 1;

    use constant Active => "active";
    use constant Pending => "pending";
    use constant Suspended => "suspended";
}

{
    package WebService::Braintree::MerchantAccount::FundingDestination;
$WebService::Braintree::MerchantAccount::FundingDestination::VERSION = '1.2';
use 5.010_001;
    use strictures 1;

    use constant Bank => "bank";
    use constant Email => "email";
    use constant MobilePhone => "mobile_phone";
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
