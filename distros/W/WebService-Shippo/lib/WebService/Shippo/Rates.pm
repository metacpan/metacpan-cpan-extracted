use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Rates;
require WebService::Shippo::Rate;
use base qw(
    WebService::Shippo::Collection
    WebService::Shippo::Fetch
);

sub item_class () { 'WebService::Shippo::Rate' }

sub collection_class () { __PACKAGE__ }

BEGIN {
    no warnings 'once';
    *Shippo::Rates:: = *WebService::Shippo::Rates::;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::Rate - Rate collection class

=head1 VERSION

version 0.0.21

=head1 DESCRIPTION

Each valid Shipment object will automatically trigger the calculation
of all available rates. Depending on the state of the shipment's address
and parcel elements, there may be none, one or multiple rates.

By default, the calculated rates will returned in two currencies:

=over 2

=item * The C<amount> attribute will contain the rate expressed in the
currency that is used in the country from which the parcel originates.

=item * The C<amount_local> attribute will contain the rate expressed
in the currency that is used in the country to which the parcel is being
shipped. 

=back 

You can request rates expressed in a different currency. The full list
of supported currencies, along with their codes, can be viewed on
L<open exchange rates|http://openexchangerates.org/api/currencies.json>.

Re-requesting the rates with a different currency code will
re-queue the shipment, setting the Shipment object's C<object_status>
attribute to B<QUEUED>; the converted currency rates will only be
available once that attribute has been set to B<SUCCESS>.

Rates are created asynchronously. The response time depends exclusively
on the carrier's server.

=head1 API DOCUMENTATION

For more information about Rates, consult the Shippo API documentation:

=over 2

=item * L<https://goshippo.com/docs/#rates>

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
