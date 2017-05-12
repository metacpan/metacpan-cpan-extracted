use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Transactions;
require WebService::Shippo::Transaction;
use base qw(
    WebService::Shippo::Collection
    WebService::Shippo::Create
    WebService::Shippo::Fetch
);

sub item_class () { 'WebService::Shippo::Transaction' }

sub collection_class () { __PACKAGE__ }

BEGIN {
    no warnings 'once';
    *Shippo::Transactions:: = *WebService::Shippo::Transactions::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::Transaction - Transaction collection class

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
