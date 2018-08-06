# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::CoinbaseDetail;
$WebService::Braintree::_::Transaction::CoinbaseDetail::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::CoinbaseDetail

=head1 PURPOSE

This class represents a transaction Coinbase detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

=head2 user_id()

This is the user id for this transaction Coinbase detail.

=cut

has user_id => (
    is => 'ro',
);

=head2 user_email()

This is the user email for this transaction Coinbase detail.

=cut

has user_email => (
    is => 'ro',
);

=head2 user_name()

This is the user name for this transaction Coinbase detail.

=cut

has user_name => (
    is => 'ro',
);

=head2 token()

This is the token for this transaction Coinbase detail.

=cut

has token => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
