#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;
use Moose::Meta::Class;

use WWW::eNom::Role::ParseDomain;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::ParseDomain';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'name' );
};

subtest "$ROLE has the correct attributes" => sub {
    has_attribute_ok( $ROLE, 'sld' );
    has_attribute_ok( $ROLE, 'public_suffix' );

    subtest "$ROLE has the correct aliases" => sub {
        my $test_class = Moose::Meta::Class->create(
            'Test',
            roles   => ['WWW::eNom::Role::ParseDomain'],
            methods => {
                name => sub { },
            }
        );

        my $test_object = $test_class->new_object;

        has_method_ok( $test_object, 'tld' );
    };
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, '_build_sld' );
    has_method_ok( $ROLE, '_build_public_suffix' );
};

done_testing;
