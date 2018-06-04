# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::AchMandate;
$WebService::Braintree::_::AchMandate::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::AchMandate

=head1 PURPOSE

This class represents a ACH mandate.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 accepted_at()

This is the date this ACH mandate was accepted.

=cut

#use Scalar::Util qw(blessed);
#use DateTime;
#$self->{accepted_at} = DateTime->parse($self->{accepted_at})
#    unless (blessed($self->{accepted_at}) // '') eq 'DateTime';
has accepted_at => (
    is => 'ro',
);

=head2 text()

This is the text for this ACH mandate.

=cut

has text => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
