#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::DomainAvailability;

use Readonly;
Readonly my $CLASS => 'WWW::eNom::DomainAvailability';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    does_ok( $CLASS, 'WWW::eNom::Role::ParseDomain' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'is_available' );
};

done_testing;
