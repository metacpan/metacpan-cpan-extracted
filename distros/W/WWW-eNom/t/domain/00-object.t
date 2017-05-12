#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Domain;

use Readonly;
Readonly my $CLASS => 'WWW::eNom::Domain';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    does_ok( $CLASS, 'WWW::eNom::Role::ParseDomain' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'id' );
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'status' );
    has_attribute_ok( $CLASS, 'verification_status' );
    has_attribute_ok( $CLASS, 'is_auto_renew' );
    has_attribute_ok( $CLASS, 'is_locked' );
    has_attribute_ok( $CLASS, 'is_private' );
    has_attribute_ok( $CLASS, 'created_date' );
    has_attribute_ok( $CLASS, 'expiration_date' );
    has_attribute_ok( $CLASS, 'ns' );
    has_attribute_ok( $CLASS, 'registrant_contact' );
    has_attribute_ok( $CLASS, 'admin_contact' );
    has_attribute_ok( $CLASS, 'technical_contact' );
    has_attribute_ok( $CLASS, 'billing_contact' );
    has_attribute_ok( $CLASS, 'private_nameservers' );
    has_attribute_ok( $CLASS, 'irtp_detail' );
};

subtest "$CLASS has the correct predicates" => sub {
    has_method_ok( $CLASS, 'has_private_nameservers' );
    has_method_ok( $CLASS, 'has_irtp_detail' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_from_response' );
};

done_testing;
