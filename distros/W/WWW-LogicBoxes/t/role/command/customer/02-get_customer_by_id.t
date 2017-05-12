#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );

use WWW::LogicBoxes::Customer;

my $logic_boxes = create_api();

subtest 'Get Customer By ID That Does Not Exist' => sub {
    my $retrieved_customer;
    lives_ok {
        $retrieved_customer = $logic_boxes->get_customer_by_id( 9999999999 );
    } 'Lives through retrieving_customer';

    ok( !defined $retrieved_customer, 'Correctly does not return a customer' );
};

subtest 'Get Valid Customer By ID' => sub {
    my $customer = create_customer();

    my $retrieved_customer;
    lives_ok {
        $retrieved_customer = $logic_boxes->get_customer_by_id( $customer->id );
    } 'Lives through retrieving customer';

    is_deeply( $retrieved_customer, $customer, 'Correct customer' );
};

done_testing;
