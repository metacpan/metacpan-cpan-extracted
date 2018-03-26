# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::AddOn;
$WebService::Braintree::_::AddOn::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::AddOn

=head1 PURPOSE

This class represents an add-on.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this add-on.

=cut

has amount => (
  is => 'ro',
);

=head2 created_at()

This is when this add-on was created.

=cut

# Coerce this to Datetime
has created_at => (
  is => 'ro',
);

=head2 current_billing_cycle()

TODO

=cut

has current_billing_cycle => (
  is => 'ro',
);

=head2 description()

The description provided when creating the add-on.

=cut

has description => (
  is => 'ro',
);

=head2 id()

The id of the add-on.

=cut

has id => (
  is => 'ro',
);

=head2 kind()

The kind of the add-on.

=cut

has kind => (
  is => 'ro',
);

=head2 merchant_id()

The merchant_id of the add-on.

=cut

has merchant_id => (
  is => 'ro',
);

=head2 name()

The name provided when creating the add-on. If one was not provided, then
Braintree generated one.

=cut

has name => (
  is => 'ro',
);

=head2 never_expires()

The name provided when creating the add-on. If one was not provided, then
Braintree generated one.

C<< is_never_expires >> is an alias.

=cut

# Coerce this to Boolean.
has never_expires => (
  is => 'ro',
  alias => 'is_never_expires',
);

=head2 number_of_billing_cycles()

This is the number of billing cycles in the add-on.

=cut

# Coerce this to Int.
has number_of_billing_cycles => (
  is => 'ro',
);

=head2 quantity()

This is the quanty of the add-on.

=cut

# Coerce this to Int.
has quantity => (
  is => 'ro',
);

=head2 updated_at()

This is when this add-on was last updated. If it has never been updated,
then this should equal the L</created_at> date.

=cut

# Coerce this to Datetime
has updated_at => (
  is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
