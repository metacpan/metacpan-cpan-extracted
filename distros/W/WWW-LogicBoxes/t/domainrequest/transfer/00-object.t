#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::DomainRequest::Transfer;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::DomainRequest::Transfer';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    isa_ok( $CLASS, 'WWW::LogicBoxes::DomainRequest' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'epp_key' );
};

subtest "$CLASS has the correct predicates" => sub {
    has_method_ok( $CLASS, 'has_epp_key' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_request' );
};

done_testing;
