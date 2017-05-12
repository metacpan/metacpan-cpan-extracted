#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::DomainRequest::Registration;

use Readonly;
Readonly my $CLASS => 'WWW::eNom::DomainRequest::Registration';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    does_ok( $CLASS, 'WWW::eNom::Role::ParseDomain' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'ns' );
    has_attribute_ok( $CLASS, 'is_ns_fail_fatal' );
    has_attribute_ok( $CLASS, 'is_locked' );
    has_attribute_ok( $CLASS, 'is_auto_renew' );
    has_attribute_ok( $CLASS, 'years' );
    has_attribute_ok( $CLASS, 'is_queueable' );
    has_attribute_ok( $CLASS, 'registrant_contact' );
    has_attribute_ok( $CLASS, 'admin_contact' );
    has_attribute_ok( $CLASS, 'technical_contact' );
    has_attribute_ok( $CLASS, 'billing_contact' );
    has_attribute_ok( $CLASS, 'nexus_purpose' );
    has_attribute_ok( $CLASS, 'nexus_category' );
};

subtest "$CLASS has the correct predicates" => sub {
    has_method_ok( $CLASS, 'has_ns' );
    has_method_ok( $CLASS, 'has_nexus_purpose' );
    has_method_ok( $CLASS, 'has_nexus_category' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_request' );
};

done_testing;
