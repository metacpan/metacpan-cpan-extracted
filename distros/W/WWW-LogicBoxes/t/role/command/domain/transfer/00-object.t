#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Role::Command::Domain::Transfer;

use Readonly;
Readonly my $ROLE => 'WWW::LogicBoxes::Role::Command::Domain::Transfer';

subtest "$ROLE is a well formed roll" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'is_domain_transferable' );
    has_method_ok( $ROLE, 'transfer_domain' );
    has_method_ok( $ROLE, 'delete_domain_transfer_by_id' );
    has_method_ok( $ROLE, 'resend_transfer_approval_mail_by_id' );
};

done_testing;
