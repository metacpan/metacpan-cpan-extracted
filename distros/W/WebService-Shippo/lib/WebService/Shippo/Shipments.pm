use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Shipments;
require WebService::Shippo::Shipment;
use base qw(
    WebService::Shippo::Collection
    WebService::Shippo::Create
    WebService::Shippo::Fetch
);

sub item_class () { 'WebService::Shippo::Shipment' }

sub collection_class () { __PACKAGE__ }

BEGIN {
    no warnings 'once';
    *Shippo::Shipments:: = *WebService::Shippo::Shipments::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::Shipment - Shipment collection class

=head1 VERSION

version 0.0.21

=head1 DESCRIPTION

At the heart of the Shippo API is the Shipment object. It is made up
of sender and recipient addresses, details of the parcel to be shipped
and, for international shipments, the customs declaration. Once created,
a Shipment object can be used to retrieve shipping rates and purchase a
shipping label.

=head1 API DOCUMENTATION

For more information about Shipments, consult the Shippo API documentation:

=over 2

=item * L<https://goshippo.com/docs/#shipments>

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
