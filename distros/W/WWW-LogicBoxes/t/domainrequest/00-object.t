#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::DomainRequest;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::DomainRequest';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'customer_id' );
    has_attribute_ok( $CLASS, 'ns' );
    has_attribute_ok( $CLASS, 'registrant_contact_id' );
    has_attribute_ok( $CLASS, 'admin_contact_id' );
    has_attribute_ok( $CLASS, 'technical_contact_id' );
    has_attribute_ok( $CLASS, 'billing_contact_id' );
    has_attribute_ok( $CLASS, 'is_private' );
    has_attribute_ok( $CLASS, 'invoice_option' );
};

subtest "$CLASS has the correct predicates" => sub {
    has_method_ok( $CLASS, 'has_billing_contact_id' );
};

done_testing;
