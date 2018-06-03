# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::CustomerDetail;
$WebService::Braintree::_::Transaction::CustomerDetail::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::CustomerDetail

=head1 PURPOSE

This class represents a transaction customer detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 company()

This is the company for this transaction customer detail.

=cut

has company => (
    is => 'ro',
);

=head2 email()

This is the email for this transaction customer detail.

=cut

has email => (
    is => 'ro',
);

=head2 fax()

This is the fax for this transaction customer detail.

=cut

has fax => (
    is => 'ro',
);

=head2 first_name()

This is the first name for this transaction customer detail.

=cut

has first_name => (
    is => 'ro',
);

=head2 id()

This is the id for this transaction customer detail.

=cut

has id => (
    is => 'ro',
);

=head2 last_name()

This is the last name for this transaction customer detail.

=cut

has last_name => (
    is => 'ro',
);

=head2 phone()

This is the phone for this transaction customer detail.

=cut

has phone => (
    is => 'ro',
);

=head2 website()

This is the website for this transaction customer detail.

=cut

has website => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
