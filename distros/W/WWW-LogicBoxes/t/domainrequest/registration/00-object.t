#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::DomainRequest::Registration;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::DomainRequest::Registration';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    isa_ok( $CLASS, 'WWW::LogicBoxes::DomainRequest' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'years' );
};

subtest "$CLASS has the correct methods" => sub {
    has_method_ok( $CLASS, 'construct_request' );
};

done_testing;
