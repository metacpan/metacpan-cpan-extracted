#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command::Domain::PrivateNameServer;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command::Domain::PrivateNameServer';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );

    requires_method_ok( $ROLE, 'submit' );
    requires_method_ok( $ROLE, 'update_nameservers_for_domain_name' );
    requires_method_ok( $ROLE, 'get_domain_by_name' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'create_private_nameserver' );
    has_method_ok( $ROLE, 'retrieve_private_nameserver_by_name' );
    has_method_ok( $ROLE, 'delete_private_nameserver' );
};

done_testing;
