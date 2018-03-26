# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::ApplePay;
$WebService::Braintree::_::ApplePay::VERSION = '1.2';
use 5.010_001;
use strictures 1;


=head1 NAME

WebService::Braintree::_::ApplePay

=head1 PURPOSE

This class represents an apple-pay response.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 METHODS

This class has no attributes according to the Ruby SDK and doesn't exist in
either the Python or NodeJS SDKs. Given I cannot test this class, I'll wait
for bug reports to fix it.

=cut

__PACKAGE__->meta->make_immutable;

1;
__END__
