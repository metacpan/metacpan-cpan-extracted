# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Plan;
$WebService::Braintree::Plan::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Plan

=head1 PURPOSE

This class lists all subscription plans.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head2 all()

This returns all the plans.

=cut

sub all {
    my $class = shift;
    $class->gateway->plan->all;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
