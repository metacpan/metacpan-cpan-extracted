#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::DomainAvailability;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::DomainAvailability';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'is_available' );
    has_attribute_ok( $CLASS, 'sld' );
    has_attribute_ok( $CLASS, 'public_suffix' );
    has_method_ok( $CLASS, 'tld' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, '_build_sld' );
    has_method_ok( $CLASS, '_build_public_suffix' );
};

done_testing;
