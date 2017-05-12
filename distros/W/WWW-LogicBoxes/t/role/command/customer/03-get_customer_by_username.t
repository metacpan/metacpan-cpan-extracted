#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );

use WWW::LogicBoxes::Customer;

my $logic_boxes = create_api();

subtest 'Get Customer By Username That Does Not Exist' => sub {
    my $retrieved_customer;
    lives_ok {
        $retrieved_customer = $logic_boxes->get_customer_by_username(
            'test-' . random_string('nnccnnccnnccnnccnnccnncc') . '@does-not-exist.com',
        );
    } 'Lives through retrieving_customer';

    ok( !defined $retrieved_customer, 'Correctly does not return a customer' );
};

subtest 'Get Valid Customer By Username' => sub {
    my $customer = create_customer();

    my $retrieved_customer;
    lives_ok {
        $retrieved_customer = $logic_boxes->get_customer_by_username( $customer->username );
    } 'Lives through retrieving customer';

    is_deeply( $retrieved_customer, $customer, 'Correct customer' );
};

done_testing;
