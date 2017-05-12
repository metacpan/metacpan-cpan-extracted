#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::IRTPDetail;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::IRTPDetail';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'is_transfer_locked' );
    has_attribute_ok( $CLASS, 'expiration_date' );
    has_attribute_ok( $CLASS, 'gaining_foa_status' );
    has_attribute_ok( $CLASS, 'losing_foa_status' );
    has_attribute_ok( $CLASS, 'status' );
    has_attribute_ok( $CLASS, 'message' );
    has_attribute_ok( $CLASS, 'proposed_registrant_contact_id' );
};

subtest "$CLASS has the correct predicates" => sub {
    has_method_ok( $CLASS, 'has_message' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_from_response' );
};

done_testing;
