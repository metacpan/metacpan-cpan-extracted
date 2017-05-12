#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );

subtest 'Get CA Registrant Agreement' => sub {
    my $logic_boxes = create_api();

    my $agreement;
    lives_ok {
        $agreement = $logic_boxes->get_ca_registrant_agreement();
    } 'Lives through retrieving CA Registrant Agreement';

    if( isa_ok( $agreement, 'WWW::LogicBoxes::Contact::CA::Agreement' ) ) {
        like( $agreement->version, qr/(?:\d|\.)*$/, 'Version looks valid' );
        like( $agreement->content, qr/^<html>/, 'Content looks valid' );
    }
};

done_testing;
