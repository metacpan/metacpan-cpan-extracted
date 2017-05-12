#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'response_type' );

    does_ok( $ROLE, 'WWW::eNom::Role::Command::Raw' );
    does_ok( $ROLE, 'WWW::eNom::Role::Command::Contact' );
    does_ok( $ROLE, 'WWW::eNom::Role::Command::Domain' );
    does_ok( $ROLE, 'WWW::eNom::Role::Command::Domain::Availability' );
    does_ok( $ROLE, 'WWW::eNom::Role::Command::Domain::Registration' );
    does_ok( $ROLE, 'WWW::eNom::Role::Command::Domain::Transfer' );
    does_ok( $ROLE, 'WWW::eNom::Role::Command::Domain::PrivateNameServer' );
    does_ok( $ROLE, 'WWW::eNom::Role::Command::Service' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'submit' );
};

done_testing;
