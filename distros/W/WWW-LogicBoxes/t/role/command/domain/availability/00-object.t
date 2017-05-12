#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::LogicBoxes::Role::Command::Domain::Availability;

use Readonly;
Readonly my $ROLE => 'WWW::LogicBoxes::Role::Command::Domain::Availability';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'check_domain_availability' );
    has_method_ok( $ROLE, 'suggest_domain_names' );
};

done_testing;
