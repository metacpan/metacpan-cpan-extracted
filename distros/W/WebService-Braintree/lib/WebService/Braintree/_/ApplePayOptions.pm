# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::ApplePayOptions;
$WebService::Braintree::_::ApplePayOptions::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::ApplePayOptions

=head1 PURPOSE

This class represents the ApplePay options.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 domains()

These are the domains returned.

=cut

# Coerce this to an ArrayRefOf???
has domains => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
