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
use Test::WWW::eNom::Domain::Transfer qw( create_transfer mock_domain_transfer );

use WWW::eNom::DomainRequest::Transfer;

subtest 'Invalid Order ID' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'TP_GetOrderDetail',
        response => {
            ErrCount => 1,
            errors   => [ 'Transfer Order Detail record does not exist.' ],
        }
    );

    throws_ok {
        $api->get_transfer_by_order_id( 999_999_999 );
    } qr/No transfer found in your account with specified id/, 'Throws on bad order id';
};

subtest 'Valid Transfer' => sub {
    my $api = create_api();

    my $transfer_details = {
        name                  => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnncc') . '.com',
        verification_method   => 'Autoverification',
        is_private            => 1,
        is_locked             => 1,
        is_auto_renew         => 1,
        epp_key               => '12345',
        use_existing_contacts => 0,
        registrant_contact    => create_contact(),
        admin_contact         => create_contact(),
        technical_contact     => create_contact(),
        billing_contact       => create_contact(),
    };

    my $transfer = create_transfer( $transfer_details );

    my $mocked_api = mock_domain_transfer( request => WWW::eNom::DomainRequest::Transfer->new( $transfer_details ) );

    my $retrieved_transfer;
    lives_ok {
        $retrieved_transfer = $api->get_transfer_by_order_id( $transfer->order_id );
    } 'Lives through retrieving domain transfer';

    if( isa_ok( $retrieved_transfer, 'WWW::eNom::DomainTransfer' ) ) {
        like( $retrieved_transfer->order_id, qr/^\d+$/, 'order_id looks numeric' );
        cmp_ok( $retrieved_transfer->name,                  'eq', lc $transfer_details->{name}, 'Correct name' );
        cmp_ok( $retrieved_transfer->is_locked,             '==', $transfer_details->{is_locked}, 'Correct is_locked' );
        cmp_ok( $retrieved_transfer->is_auto_renew,         '==', $transfer_details->{is_auto_renew}, 'Correct is_auto_renew' );
        cmp_ok( $retrieved_transfer->use_existing_contacts, '==',
            $transfer_details->{use_existing_contacts}, 'Correct use_existing_contacts' );
    }

    $mocked_api->unmock_all;
};

done_testing;
