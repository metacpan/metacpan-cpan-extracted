#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom;

use Readonly;
Readonly my $CLASS => 'WWW::eNom';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
    does_ok( $CLASS, 'WWW::eNom::Role::Command' );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'username' );
    has_attribute_ok( $CLASS, 'password' );
    has_attribute_ok( $CLASS, 'test' );
    has_attribute_ok( $CLASS, 'response_type' );
    has_attribute_ok( $CLASS, '_uri' );
};

subtest "$CLASS has the correct builders" => sub {
    has_method_ok( $CLASS, '_build_uri' );
};

done_testing;
