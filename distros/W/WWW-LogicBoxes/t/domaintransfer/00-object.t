#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::DomainTransfer;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::DomainTransfer';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'id' );
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'customer_id' );
    has_attribute_ok( $CLASS, 'status' );
    has_attribute_ok( $CLASS, 'transfer_status' );
    has_attribute_ok( $CLASS, 'verification_status' );
    has_attribute_ok( $CLASS, 'ns' );
    has_attribute_ok( $CLASS, 'registrant_contact_id' );
    has_attribute_ok( $CLASS, 'admin_contact_id' );
    has_attribute_ok( $CLASS, 'technical_contact_id' );
    has_attribute_ok( $CLASS, 'billing_contact_id' );
    has_attribute_ok( $CLASS, 'epp_key' );
    has_attribute_ok( $CLASS, 'private_nameservers' );
};

subtest "$CLASS has the correct predicates" => sub {
    has_method_ok( $CLASS, 'has_epp_key' );
    has_method_ok( $CLASS, 'has_private_nameservers' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_from_response' );
};

done_testing;
