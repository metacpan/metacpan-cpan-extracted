#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Role::Command::Contact;

use Readonly;
Readonly my $ROLE => 'WWW::LogicBoxes::Role::Command::Contact';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'create_contact' );
    has_method_ok( $ROLE, 'get_contact_by_id' );
    has_method_ok( $ROLE, 'update_contact' );
    has_method_ok( $ROLE, 'delete_contact_by_id' );
};

done_testing;
