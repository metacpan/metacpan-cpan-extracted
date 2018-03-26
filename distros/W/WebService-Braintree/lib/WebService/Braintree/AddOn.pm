# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::AddOn;
$WebService::Braintree::AddOn::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::AddOn

=head1 PURPOSE

This class lists all add-ons

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head2 all()

This returns all the add-ons. This will be an arrayref of L<AddOn|WebService::Braintree::_::AddOn>s. If none are found, then an empty arrayref.

This does B<NOT> return a result or error-result object.

=cut

sub all {
    my $class = shift;
    $class->gateway->add_on->all;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
