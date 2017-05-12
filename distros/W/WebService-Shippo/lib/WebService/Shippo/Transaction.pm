use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Transaction;
use Carp         ( 'confess' );
use Scalar::Util ( 'blessed' );
use base qw(
    WebService::Shippo::Item
    WebService::Shippo::Create
    WebService::Shippo::Fetch
    WebService::Shippo::Async
);

sub api_resource () { 'transactions' }

sub collection_class () { 'WebService::Shippo::Transactions' }

sub item_class () { __PACKAGE__ }

sub get_shipping_label
{
    my ( $invocant, $transaction_id, %params ) = @_;
    confess "Expected a transaction id"
        unless $transaction_id;
    my $transaction;
    if ( $invocant->is_same_object( $transaction_id ) ) {
        $transaction = $invocant;
    }
    else {
        $transaction = WebService::Shippo::Transaction->fetch( $transaction_id );
    }
    $transaction->wait_if_status_in( 'QUEUED', 'WAITING' )
        unless $params{async};
    return $transaction->label_url;
}

BEGIN {
    no warnings 'once';
    *Shippo::Transaction:: = *WebService::Shippo::Transaction::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::Transaction - Transaction class

=head1 VERSION

version 0.0.21

=head1 DESCRIPTION

A Transaction is the purchase of a shipment label for a given shipment
rate. Transactions can be as simple as posting a rate identifier, but
also allow you to define further label parameters, such as pickup and
notifications.

Transactions can only be created for rates that are less than 7 days
old and whose C<object_purpose> attribute is B<PURCHASE>.

Transactions are created asynchronously. The response time depends
exclusively on the carrier's server.

=head1 API DOCUMENTATION

For more information about Transactions, consult the Shippo API
documentation:

=over 2

=item * L<https://goshippo.com/docs/#transactions>

=back

=head1 REPOSITORY

=over 2

=item * L<https://github.com/cpanic/WebService-Shippo>

=item * L<https://github.com/cpanic/WebService-Shippo/wiki>

=back

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Iain Campbell.

You may distribute this software under the terms of either the GNU General
Public License or the Artistic License, as specified in the Perl README
file.

=cut
