#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Role::Command::Domain::Registration;

use Readonly;
Readonly my $ROLE => 'WWW::LogicBoxes::Role::Command::Domain::Registration';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
    requires_method_ok( $ROLE, 'get_domain_by_id' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'register_domain' );
};

done_testing;
