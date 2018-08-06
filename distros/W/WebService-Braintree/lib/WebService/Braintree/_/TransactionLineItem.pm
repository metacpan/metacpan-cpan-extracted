# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::TransactionLineItem;
$WebService::Braintree::_::TransactionLineItem::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::TransactionLineItem

=head1 PURPOSE

This class represents a transaction line-item.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 commodity_code()

This is the commodity code for this transaction line-item.

=cut

has commodity_code => (
    is => 'ro',
);

=head2 description()

This is the description for this transaction line-item.

=cut

has description => (
    is => 'ro',
);

=head2 discount_amount()

This is the discount amount for this transaction line-item.

=cut

# Coerce to "big_decimal"
has discount_amount => (
    is => 'ro',
);

=head2 kind()

This is the kind for this transaction line-item.

=cut

has kind => (
    is => 'ro',
);

=head2 name()

This is the name for this transaction line-item.

=cut

has name => (
    is => 'ro',
);

=head2 product_code()

This is the product code for this transaction line-item.

=cut

has product_code => (
    is => 'ro',
);

=head2 quantity()

This is the quantity for this transaction line-item.

=cut

# Coerce to "big_decimal"
has quantity => (
    is => 'ro',
);

=head2 total_amount()

This is the total amount for this transaction line-item.

=cut

# Coerce to "big_decimal"
has total_amount => (
    is => 'ro',
);

=head2 unit_amount()

This is the unit amount for this transaction line-item.

=cut

# Coerce to "big_decimal"
has unit_amount => (
    is => 'ro',
);

=head2 unit_of_measure()

This is the unit of measure for this transaction line-item.

=cut

has unit_of_measure => (
    is => 'ro',
);

=head2 unit_tax_amount()

This is the unit tax amount for this transaction line-item.

=cut

# Coerce to "big_decimal"
has unit_tax_amount => (
    is => 'ro',
);

=head2 url()

This is the url for this transaction line-item.

=cut

# Coerce to URI
has url => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
