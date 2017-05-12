#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Contact;

use Readonly;
Readonly my $CLASS => 'WWW::eNom::Contact';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'first_name' );
    has_attribute_ok( $CLASS, 'last_name' );
    has_attribute_ok( $CLASS, 'organization_name' );
    has_attribute_ok( $CLASS, 'job_title' );
    has_attribute_ok( $CLASS, 'address1' );
    has_attribute_ok( $CLASS, 'address2' );
    has_attribute_ok( $CLASS, 'city' );
    has_attribute_ok( $CLASS, 'state' );
    has_attribute_ok( $CLASS, 'country' );
    has_attribute_ok( $CLASS, 'zipcode' );
    has_attribute_ok( $CLASS, 'email' );
    has_attribute_ok( $CLASS, 'phone_number' );
    has_attribute_ok( $CLASS, 'fax_number' );
};

subtest "$CLASS has the correct predicates and clearers" => sub {
    has_method_ok( $CLASS, 'has_organization_name' );
    has_method_ok( $CLASS, 'clear_organization_name' );
    has_method_ok( $CLASS, 'has_job_title' );
    has_method_ok( $CLASS, 'clear_job_title' );
    has_method_ok( $CLASS, 'has_address2' );
    has_method_ok( $CLASS, 'clear_address2' );
    has_method_ok( $CLASS, 'has_state' );
    has_method_ok( $CLASS, 'clear_state' );
    has_method_ok( $CLASS, 'has_fax_number' );
    has_method_ok( $CLASS, 'clear_fax_number' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_creation_request' );
    has_method_ok( $CLASS, 'construct_from_response' );
};

done_testing;
