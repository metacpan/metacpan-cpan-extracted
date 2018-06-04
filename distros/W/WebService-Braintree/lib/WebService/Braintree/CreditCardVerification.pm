# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::CreditCardVerification;
$WebService::Braintree::CreditCardVerification::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::CreditCardVerification

=head1 PURPOSE

This class searches, lists, and finds credit card verifications.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 search()

This takes a subref which is used to set the search parameters and returns a
L<collection|WebService::Braintree::ResourceCollection> of the matching
L<verifications|WebService::Braintree::_::CreditCardVerification>.

Please see L<Searching|WebService::Braintree/SEARCHING> for more information on
the subref and how it works.

Please see L<WebService::Braintree::CreditCardVerificationSearch> for more
information on what specfic fields you can set for this method.

=cut

sub search {
    my ($class, $block) = @_;
    $class->gateway->verification->search($block);
}

=head2 all()

This returns a L<collection|WebService::Braintree::ResourceCollection> of all
L<verifications|WebService::Braintree::_::CreditCardVerification>.

=cut

sub all {
    my $class = shift;
    $class->gateway->verification->all;
}

=head2 find()

This takes a token and returns a L<response|WebService::Braintee::Result> with
the C<< credit_card_verification() >> set (if found).

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->verification->find($token);
}

=head2 create()

This takes a hashref of parameters and returns a L<response|WebService::Braintee::Result> with the C<< credit_card_verification() >> set.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->verification->create($params);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
