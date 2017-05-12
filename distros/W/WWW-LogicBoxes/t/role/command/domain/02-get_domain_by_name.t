#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

use WWW::LogicBoxes::Domain;

my $logic_boxes = create_api;

subtest 'Get Domain By Name That Does Not Exist' => sub {
    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $logic_boxes->get_domain_by_name(
            'does-not-exist-' . random_string('ccnnccnnccnnccnnccnn') . '.com'
        );
    } 'Lives through retrieving domain';

    ok( !defined $retrieved_domain, 'Correctly does not return a domain' );
};

subtest 'Get Valid Domain By Name' => sub {
    my $domain = create_domain();

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $logic_boxes->get_domain_by_name( $domain->name );
    } 'Lives through retrieving domain';

    is_deeply( $retrieved_domain, $domain, 'Correct domain' );
};

done_testing;
