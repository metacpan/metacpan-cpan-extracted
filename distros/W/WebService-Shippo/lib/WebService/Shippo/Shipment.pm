use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Shipment;
require WebService::Shippo::Rate;
use Carp              ( 'confess' );
use Params::Callbacks ( 'callbacks', 'callback' );
use Scalar::Util      ( 'blessed' );
use base qw(
    WebService::Shippo::Item
    WebService::Shippo::Create
    WebService::Shippo::Fetch
    WebService::Shippo::Currency
    WebService::Shippo::Async
);

sub api_resource () { 'shipments' }

sub collection_class () { 'WebService::Shippo::Shipments' }

sub item_class () { __PACKAGE__ }

sub get_shipping_rates
{
    my ( $callbacks, $invocant, $shipment_id, @params ) = &callbacks;
    confess "Expected a shipment id"
        unless $shipment_id;
    my $shipment;
    if ( $invocant->is_same_object( $shipment_id ) ) {
        $shipment = $invocant;
    }
    else {
        $shipment = WebService::Shippo::Shipment->fetch( $shipment_id );
    }
    my $currency;
    if ( @params && @params % 2 ) {
        ( $currency, @params ) = @params;
        $currency = $invocant->validate_currency( $currency );
    }
    my $rates_url = "$shipment_id/rates";
    $rates_url .= "/$currency"
        if $currency;
    $rates_url = $invocant->url( $rates_url );
    my $async;
    my %params = @params;
    $async = delete( $params{async} )
        if exists $params{async};
    @params = %params;

    unless ( $async ) {
        WebService::Shippo::Request->get( $rates_url, @params );
        $shipment->wait_if_status_in( 'QUEUED', 'WAITING' );
    }
    my $response = WebService::Shippo::Request->get( $rates_url, @params );
    unshift @$callbacks, callback {
        return unless @_;
        return $_[0] unless defined $_[0];
        return bless( $_[0], 'WebService::Shippo::Rate' );
    };
    my $rates = WebService::Shippo::Rate->construct_from( $response, $callbacks );
    return $rates;
}

BEGIN {
    no warnings 'once';
    *Shippo::Shipment:: = *WebService::Shippo::Shipment::;
    *rates              = *get_shipping_rates;
}

1;

=pod

=encoding utf8

=head1 NAME

WebService::Shippo::Shipment - Shipment class

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
