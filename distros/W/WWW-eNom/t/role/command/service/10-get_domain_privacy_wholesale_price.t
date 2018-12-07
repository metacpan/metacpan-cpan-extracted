#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Service qw( mock_pe_getproductprice );

use Math::Currency;

use Readonly;
Readonly my $ZERO => Math::Currency->new('0.00');

subtest 'Get Domain Privacy Wholesale Price' => sub {
    my $api        = create_api();
    my $mocked_api = mock_pe_getproductprice(
        price => '9.99',
    );

    my $price;
    lives_ok {
        $price = $api->get_domain_privacy_wholesale_price( );
    } 'Lives through fetching price';

    $mocked_api->unmock_all;

    if( isa_ok( $price, 'Math::Currency' ) ) {
        note( "Default Price: $price" );
        cmp_ok( $price, '>', $ZERO, 'Price is greater than zero' );
    }
};

done_testing;
