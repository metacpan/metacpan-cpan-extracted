#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command::Domain;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command::Domain';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
    requires_method_ok( $ROLE, 'get_contacts_by_domain_name' );
    requires_method_ok( $ROLE, 'delete_private_nameserver' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'get_domain_by_name' );

    has_method_ok( $ROLE, 'get_is_domain_locked_by_name' );
    has_method_ok( $ROLE, 'enable_domain_lock_by_name' );
    has_method_ok( $ROLE, 'disable_domain_lock_by_name' );

    has_method_ok( $ROLE, 'get_domain_name_servers_by_name' );
    has_method_ok( $ROLE, 'update_nameservers_for_domain_name' );

    has_method_ok( $ROLE, 'get_is_domain_auto_renew_by_name' );
    has_method_ok( $ROLE, 'enable_domain_auto_renew_by_name' );
    has_method_ok( $ROLE, 'disable_domain_auto_renew_by_name' );

    has_method_ok( $ROLE, 'get_domain_created_date_by_name' );

    has_method_ok( $ROLE, 'renew_domain' );

    has_method_ok( $ROLE, 'email_epp_key_by_name' );
};

done_testing;
