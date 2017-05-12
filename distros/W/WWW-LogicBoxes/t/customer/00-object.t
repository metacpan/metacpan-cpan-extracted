#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Customer;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::Customer';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'id' );
    has_attribute_ok( $CLASS, 'username' );
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'company' );
    has_attribute_ok( $CLASS, 'address1' );
    has_attribute_ok( $CLASS, 'address2' );
    has_attribute_ok( $CLASS, 'address3' );
    has_attribute_ok( $CLASS, 'city' );
    has_attribute_ok( $CLASS, 'state' );
    has_attribute_ok( $CLASS, 'country' );
    has_attribute_ok( $CLASS, 'zipcode' );
    has_attribute_ok( $CLASS, 'phone_number' );
    has_attribute_ok( $CLASS, 'alt_phone_number' );
    has_attribute_ok( $CLASS, 'mobile_phone_number' );
    has_attribute_ok( $CLASS, 'fax_number' );
    has_attribute_ok( $CLASS, 'language_preference' );
};

subtest "$CLASS has the correct predicates and writers" => sub {
    has_method_ok( $CLASS, 'has_id' );
    has_method_ok( $CLASS, '_set_id' );
    has_method_ok( $CLASS, 'has_address2' );
    has_method_ok( $CLASS, 'has_address3' );
    has_method_ok( $CLASS, 'has_state' );
    has_method_ok( $CLASS, 'has_alt_phone_number' );
    has_method_ok( $CLASS, 'has_mobile_phone_number' );
    has_method_ok( $CLASS, 'has_fax_number' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_from_response' );
};

done_testing;
