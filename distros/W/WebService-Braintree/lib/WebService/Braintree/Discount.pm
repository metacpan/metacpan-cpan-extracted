# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Discount;
$WebService::Braintree::Discount::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Discount

=head1 PURPOSE

This class lists all discounts.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head2 all()

This returns all the discounts. This will be an arrayref of L<Discount|WebService::Braintree::_::Discount>s. If none are found, then an empty arrayref.

This does B<NOT> return a result or error-result object.

=cut

sub all {
    my $class = shift;
    $class->gateway->discount->all;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
