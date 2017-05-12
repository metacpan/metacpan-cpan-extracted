#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer;

use Readonly;
Readonly my $ROLE => 'WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
    requires_method_ok( $ROLE, 'get_domain_by_id' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'create_private_nameserver' );
    has_method_ok( $ROLE, 'rename_private_nameserver' );
    has_method_ok( $ROLE, 'modify_private_nameserver_ip' );
    has_method_ok( $ROLE, 'delete_private_nameserver_ip' );
    has_method_ok( $ROLE, 'delete_private_nameserver' );
};

done_testing;
