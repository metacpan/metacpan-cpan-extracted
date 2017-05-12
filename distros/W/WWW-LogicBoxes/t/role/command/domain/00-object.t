#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Role::Command::Domain;

use Readonly;
Readonly my $ROLE => 'WWW::LogicBoxes::Role::Command::Domain';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'get_domain_by_id' );
    has_method_ok( $ROLE, 'get_domain_by_name' );
    has_method_ok( $ROLE, 'update_domain_contacts' );
    has_method_ok( $ROLE, 'enable_domain_lock_by_id' );
    has_method_ok( $ROLE, 'disable_domain_lock_by_id' );
    has_method_ok( $ROLE, 'enable_domain_privacy' );
    has_method_ok( $ROLE, 'disable_domain_privacy' );
    has_method_ok( $ROLE, 'update_domain_nameservers' );
};

done_testing;
