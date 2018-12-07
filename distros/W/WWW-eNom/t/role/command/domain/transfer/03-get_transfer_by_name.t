#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Contact qw( create_contact );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN );
use Test::WWW::eNom::Domain::Transfer qw( create_transfer mock_tp_get_order_detail );

subtest 'Unregistered Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'TP_GetDetailsByDomain',
        response => {
            ErrCount => 1,
            errors   => [ 'There are no transfer order details' ],
        }
    );

    throws_ok {
        $api->get_transfer_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/No transfer found for specified domain name/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};


subtest 'Domain Registered ( Never a Transfer )' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $mocked_api = mock_response(
        method   => 'TP_GetDetailsByDomain',
        response => {
            ErrCount => 1,
            errors   => [ 'There are no transfer order details' ],
        }
    );

    throws_ok {
        $api->get_transfer_by_name( $domain->name );
    } qr/No transfer found for specified domain name/, 'Throws on domain registration';

    $mocked_api->unmock_all;
};

subtest 'Transfer' => sub {
    my $api      = create_api();
    my $transfer = create_transfer( use_existing_contacts => 1 );

    my $mocked_api = mock_response(
        method   => 'TP_GetDetailsByDomain',
        response => {
            ErrCount      => 0,
            TransferOrder => {
                orderid => 42,
            }
        }
    );

    mock_response(
        mocked_api => $mocked_api,
        method     => 'TP_GetOrder',
        response   => {
            ErrCount => 0,
            transferorder => {
                transferorderdetail => {
                    transferorderdetailid => 42,
                }
            }
        }
    );

    mock_tp_get_order_detail(
        mocked_api => $mocked_api,
        sld        => $transfer->sld,
        tld        => $transfer->tld,
        use_existing_contacts => 1,
    );

    my $transfers;
    lives_ok {
        $transfers = $api->get_transfer_by_name( $transfer->name );
    } 'Lives through retrieving transfer';

    cmp_ok( scalar @{ $transfers }, '==', 1, 'Correct number of transfer records' );
    isa_ok( $transfers->[0], 'WWW::eNom::DomainTransfer' );

    # Delete these because I generated them by calling $transfer->sld/tld
    delete $transfer->{public_suffix};
    delete $transfer->{sld};

    is_deeply( $transfers->[0], $transfer, 'Correct transfer information' );

    $mocked_api->unmock_all;
};

# The response on this is the same 'No transfer found for...' error but finding
# a domain I can use here that will never have an actual transfer for it
# is problematic.
#subtest 'Domain Registered To Someone Else' => sub {
done_testing;
