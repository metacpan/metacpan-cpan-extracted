#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Role::Command::Raw;

use Readonly;
Readonly my $ROLE => 'WWW::LogicBoxes::Role::Command::Raw';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'username' );
    requires_method_ok( $ROLE, 'password' );
    requires_method_ok( $ROLE, 'api_key' );
    requires_method_ok( $ROLE, 'response_type' );
    requires_method_ok( $ROLE, '_base_uri' );
};

subtest "$ROLE has the correct attributes" => sub {
    has_attribute_ok( $ROLE, 'api_methods' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'install_methods');
    has_method_ok( $ROLE, '_make_query_string');
    has_method_ok( $ROLE, '_construct_get_args');
};

done_testing;
