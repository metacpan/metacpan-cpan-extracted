#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Contact::CA::Agreement;

use Readonly;
Readonly my $CLASS => 'WWW::LogicBoxes::Contact::CA::Agreement';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'version' );
    has_attribute_ok( $CLASS, 'content' );
};

done_testing;
