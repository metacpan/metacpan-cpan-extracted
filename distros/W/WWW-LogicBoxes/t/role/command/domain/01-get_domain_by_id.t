#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

use WWW::LogicBoxes::Domain;

my $logic_boxes = create_api;

subtest 'Get Domain By ID That Does Not Exist' => sub {
    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $logic_boxes->get_domain_by_id( 999999999 );
    } 'Lives through retrieving domain';

    ok( !defined $retrieved_domain, 'Correctly does not return a domain' );
};

subtest 'Get Valid Domain By ID' => sub {
    my $domain = create_domain();

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
    } 'Lives through retrieving domain';

    is_deeply( $retrieved_domain, $domain, 'Correct domain' );
    ok( !$retrieved_domain->has_private_nameservers, 'Correctly lacks private nameservers' );
};

done_testing;
