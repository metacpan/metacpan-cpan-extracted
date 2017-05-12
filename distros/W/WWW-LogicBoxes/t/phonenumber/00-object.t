#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::PhoneNumber;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::PhoneNumber';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, '_number_phone_obj' );
    has_attribute_ok( $CLASS, 'country_code' );
    has_attribute_ok( $CLASS, 'number' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, '_build_country_code' );
    has_method_ok( $CLASS, '_build_number' );
    has_method_ok( $CLASS, '_to_string' );
};

done_testing;
