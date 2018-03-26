# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Descriptor;
$WebService::Braintree::_::Descriptor::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Descriptor

=head1 PURPOSE

This class represents a descriptor.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 name()

This is the name for this descriptor.

=cut

has name => (
    is => 'ro',
);

=head2 phone()

This is the phone for this descriptor.

=cut

has phone => (
    is => 'ro',
);

=head2 url()

This is the url for this descriptor.

=cut

# Coerce this to URI
has url => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
