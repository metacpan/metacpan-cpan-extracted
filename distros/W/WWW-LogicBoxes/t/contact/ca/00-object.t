#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Contact::CA;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::Contact::CA';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    isa_ok( $CLASS, 'WWW::LogicBoxes::Contact' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'cpr' );
    has_attribute_ok( $CLASS, 'agreement_version' );
    has_attribute_ok( $CLASS, 'type' );
};

subtest "$CLASS has the correct predicates" => sub {
    has_method_ok( $CLASS, 'has_agreement_version' );
};

done_testing;
