# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Address;
$WebService::Braintree::_::Address::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Address

=head1 PURPOSE

This class represents an address.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut


=head2 company()

This is the company for this address.

=cut

has company => (
    is => 'ro',
);

=head2 country_code_alpha2()

This is the country_code_alpha2 for this address.

=cut

has country_code_alpha2 => (
    is => 'ro',
);

=head2 country_code_alpha3()

This is the country_code_alpha3 for this address.

=cut

has country_code_alpha3 => (
    is => 'ro',
);

=head2 country_code_numeric()

This is the country_code_numeric for this address.

=cut

has country_code_numeric => (
    is => 'ro',
);

=head2 country_name()

This is the country name for this address.

=cut

has country_name => (
    is => 'ro',
);

=head2 created_at()

This is when this address was created.

=cut

# Coerce this to Datetime
has created_at => (
    is => 'ro',
);

=head2 customer_id()

This is the customer (if any) for this address.

=cut

has customer_id => (
    is => 'ro',
);

=head2 extended_address()

This is the extended_address for this address.

=cut

has extended_address => (
    is => 'ro',
);

=head2 first_name()

This is the first name for this address. This defaults to "".

=cut

has first_name => (
    is => 'ro',
    default => sub { '' },
);

=head2 id()

This is the id for this address.

=cut

has id => (
    is => 'ro',
);

=head2 last_name()

This is the last name for this address. This defaults to "".

=cut

has last_name => (
    is => 'ro',
    default => sub { '' },
);

=head2 locality()

This is the locality for this address.

=cut

has locality => (
    is => 'ro',
);

=head2 postal_code()

This is the postal code for this address.

C<< zip_code() >> is an alias for this attribute.

=cut

has postal_code => (
    is => 'ro',
    alias => 'zip_code',
);

=head2 region()

This is the region for this address.

=cut

has region => (
    is => 'ro',
);

=head2 street_address()

This is the street address for this address.

=cut

has street_address => (
    is => 'ro',
);

=head2 updated_at()

This is when this address was last updated.

=cut

# Coerce this to Datetime
has updated_at => (
    is => 'ro',
);

=head1 METHODS

=head2 full_name()

This returns the full name of this address. This is the first_name and the
last_name concatenated with a space.

=cut

sub full_name {
    my $self = shift;
    return $self->first_name . " " . $self->last_name
}

__PACKAGE__->meta->make_immutable;

1;
__END__
