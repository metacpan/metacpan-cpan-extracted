#!/usr/bin/env perl

################################################################################
# NOTE - This filename does not match the method (unlike all other test files) #
# on purpose.  This is because a length of 40 characters in a file name is     #
# too long for VMS Systems                                                     #
################################################################################

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain::Transfer qw( create_transfer );

subtest 'Invalid Order ID' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'TP_GetOrder',
        response => {
            ErrCount => 1,
            errors   => [ 'Transfer Order does not exist.' ],
        }
    );

    throws_ok {
        $api->get_transfer_order_id_from_parent_order_id( 999_999_999 );
    } qr/No transfer found for specified parent order id/, 'Throws on invalid order id';


    $mocked_api->unmock_all;
};

subtest 'Valid Transfer' => sub {
    my $api      = create_api();
    my $transfer = create_transfer();

    my $mocked_api = mock_response(
        method     => 'TP_GetDetailsByDomain',
        response   => {
            ErrCount      => 0,
            TransferOrder => {
                orderid => 42
            }
        }
    );

    my $parent_order_id;
    lives_ok {
        my $response = $api->submit({
            method => 'TP_GetDetailsByDomain',
            params => {
                Domain => $transfer->name,
            }
        });

        $parent_order_id = $response->{TransferOrder}{orderid};
    } 'Lives through fetching parent_order_id';

    mock_response(
        mocked_api => $mocked_api,
        method     => 'TP_GetOrder',
        response   => {
            ErrCount      => 0,
            transferorder => {
                transferorderdetail => {
                    transferorderdetailid => 42
                }
            }
        }
    );

    my $transfer_order_id;
    lives_ok {
        $transfer_order_id = $api->get_transfer_order_id_from_parent_order_id( $parent_order_id );
    } 'Lives through retrieving transfer order id';

    $mocked_api->unmock_all;

    cmp_ok( $transfer_order_id, '==', $transfer->order_id, 'Correct transfer_order_id' );
};

done_testing;
