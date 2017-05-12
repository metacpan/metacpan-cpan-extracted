#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    does_ok( $CLASS, 'WWW::LogicBoxes::Role::Command' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'username' );
    has_attribute_ok( $CLASS, 'password' );
    has_attribute_ok( $CLASS, 'api_key' );
    has_attribute_ok( $CLASS, 'sandbox' );
    has_attribute_ok( $CLASS, 'response_type' );
    has_attribute_ok( $CLASS, '_base_uri' );
};

subtest "$CLASS has the correct predicates and aliases" => sub {
    has_method_ok( $CLASS, 'has_password' );
    has_method_ok( $CLASS, 'has_api_key' );
    has_method_ok( $CLASS, 'apikey' );
    has_method_ok( $CLASS, '_build_base_uri' );
};

done_testing;
