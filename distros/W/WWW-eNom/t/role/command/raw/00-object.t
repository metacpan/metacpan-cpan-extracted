#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command::Raw;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command::Raw';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );

    requires_method_ok( $ROLE, 'username' );
    requires_method_ok( $ROLE, 'password' );
    requires_method_ok( $ROLE, '_uri' );
    requires_method_ok( $ROLE, 'response_type' );
};

subtest "$ROLE has the correct attributes" => sub {
    has_attribute_ok( $ROLE, '_api_commands' );
    has_attribute_ok( $ROLE, '_ua' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'install_methods' );
    has_method_ok( $ROLE, '_make_query_string' );
    has_method_ok( $ROLE, '_split_domain' );
    has_method_ok( $ROLE, '_serialize_xml_simple_response' );
};

done_testing;
