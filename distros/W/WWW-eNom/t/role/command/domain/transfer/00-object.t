#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command::Domain::Transfer;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command::Domain::Transfer';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );

    requires_method_ok( $ROLE, 'submit' );
    requires_method_ok( $ROLE, 'get_domain_privacy_wholesale_price' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'transfer_domain' );
    has_method_ok( $ROLE, 'get_transfer_by_order_id' );
    has_method_ok( $ROLE, 'get_transfer_by_name' );
    has_method_ok( $ROLE, 'get_transfer_order_id_from_parent_order_id' );
};

done_testing;
