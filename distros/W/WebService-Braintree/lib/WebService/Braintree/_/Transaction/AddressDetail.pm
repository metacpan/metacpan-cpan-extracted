# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::AddressDetail;
$WebService::Braintree::_::Transaction::AddressDetail::VERSION = '1.5';
=head1 NAME

WebService::Braintree::_::Transaction::AddressDetail

=head1 PURPOSE

This class represents a transaction address detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use 5.010_001;
use strictures 1;

use Moose;

extends 'WebService::Braintree::_';

=head2 company()

This is the company for this transaction address detail.

=cut

has company => (
    is => 'ro',
);

=head2 country_code_alpha2()

This is the country code alpha2 for this transaction address detail.

=cut

has country_code_alpha2 => (
    is => 'ro',
);

=head2 country_code_alpha3()

This is the country code alpha3 for this transaction address detail.

=cut

has country_code_alpha3 => (
    is => 'ro',
);

=head2 country_code_numeric()

This is the numeric country code for this transaction address detail.

=cut

has country_code_numeric => (
    is => 'ro',
);

=head2 country_name()

This is the country name for this transaction address detail.

=cut

has country_name => (
    is => 'ro',
);

=head2 extended_address()

This is the extended address for this transaction address detail.

=cut

has extended_address => (
    is => 'ro',
);

=head2 first_name()

This is the first name for this transaction address detail.

=cut

has first_name => (
    is => 'ro',
);

=head2 id()

This is the id for this transaction address detail.

=cut

has id => (
    is => 'ro',
);

=head2 last_name()

This is the last name for this transaction address detail.

=cut

has last_name => (
    is => 'ro',
);

=head2 locality()

This is the locality for this transaction address detail.

=cut

has locality => (
    is => 'ro',
);

=head2 postal_code()

This is the postal code for this transaction address detail.

=cut

has postal_code => (
    is => 'ro',
);

=head2 region()

This is the region for this transaction address detail.

=cut

has region => (
    is => 'ro',
);

=head2 street_address()

This is the street address for this transaction address detail.

=cut

has street_address => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
