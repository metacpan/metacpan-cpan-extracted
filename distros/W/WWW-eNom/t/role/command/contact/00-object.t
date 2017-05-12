#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command::Contact;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command::Contact';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'get_contacts_by_domain_name' );
    has_method_ok( $ROLE, 'update_contacts_for_domain_name' );
};

done_testing;
