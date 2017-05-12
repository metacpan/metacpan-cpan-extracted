#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Contact::US;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::Contact::US';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    isa_ok( $CLASS, 'WWW::LogicBoxes::Contact' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'nexus_purpose' );
    has_attribute_ok( $CLASS, 'nexus_category' );
};

done_testing;
