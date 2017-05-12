#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Role::Command::Customer;

use Readonly;
Readonly my $ROLE => 'WWW::LogicBoxes::Role::Command::Customer';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'create_customer' );
    has_method_ok( $ROLE, 'get_customer_by_id' );
    has_method_ok( $ROLE, 'get_customer_by_username' );
};

done_testing;
