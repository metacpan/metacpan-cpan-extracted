# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::ThreeDSecureInfo;
$WebService::Braintree::_::ThreeDSecureInfo::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::ThreeDSecureInfo

=head1 PURPOSE

This class represents a ThreeD secure info.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head2 enrolled()

This is the additional processor response for this ThreeD secure info.

C<< is_enrolled() >> is an alias to this attribute.

=cut

has enrolled => (
    is => 'ro',
    alias => 'is_liability_shifted',
);

=head2 liability_shifted()

This is true if the liability has shifted.

C<< is_liability_shifted() >> is an alias to this attribute.

=cut

has liability_shifted => (
    is => 'ro',
    alias => 'is_liability_shifted',
);

=head2 liability_shift_possible()

This is true if a liability shift is possible.

C<< is_liability_shift_possible() >> is an alias to this attribute.

=cut

has liability_shift_possible => (
    is => 'ro',
    alias => 'is_liability_shift_possible',
);

=head2 status()

This is the status for this ThreeD secure info.

=cut

has status => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
