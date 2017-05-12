#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Domain;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::Domain';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'id' );
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'customer_id' );
    has_attribute_ok( $CLASS, 'status' );
    has_attribute_ok( $CLASS, 'verification_status' );
    has_attribute_ok( $CLASS, 'is_locked' );
    has_attribute_ok( $CLASS, 'is_private' );
    has_attribute_ok( $CLASS, 'created_date' );
    has_attribute_ok( $CLASS, 'expiration_date' );
    has_attribute_ok( $CLASS, 'ns' );
    has_attribute_ok( $CLASS, 'registrant_contact_id' );
    has_attribute_ok( $CLASS, 'admin_contact_id' );
    has_attribute_ok( $CLASS, 'technical_contact_id' );
    has_attribute_ok( $CLASS, 'billing_contact_id' );
    has_attribute_ok( $CLASS, 'epp_key' );
    has_attribute_ok( $CLASS, 'private_nameservers' );
    has_attribute_ok( $CLASS, 'irtp_detail' );
};

subtest "$CLASS has the correct predicates" => sub {
    has_method_ok( $CLASS, 'has_private_nameservers' );
    has_method_ok( $CLASS, 'has_billing_contact_id' );
    has_method_ok( $CLASS, 'has_irtp_detail' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_from_response' );
};

done_testing;
