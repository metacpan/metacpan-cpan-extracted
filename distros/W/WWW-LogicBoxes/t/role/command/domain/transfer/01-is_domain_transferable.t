#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

my $logic_boxes = create_api();

subtest 'Unregistered Domain' => sub {
    my $domain_name = 'unregistered-domain-' . random_string('ccnnccnnccnnccnnccnnccnn') . '.com';

    my $is_transferable;
    lives_ok {
        $is_transferable = $logic_boxes->is_domain_transferable( $domain_name );
    } 'Lives through checking if domain is transferable';

    ok( !$is_transferable, 'Domain is correctly not transferable' );
};

subtest 'Domain Newly Registered' => sub {
    my $domain = create_domain();

    my $is_transferable;
    lives_ok {
        $is_transferable = $logic_boxes->is_domain_transferable( $domain->name );
    } 'Lives through checking if domain is transferable';

    ok( !$is_transferable, 'Domain is correctly not transferable' );
};

subtest 'Long Term Registered Domain' => sub {
    my $is_transferable;
    lives_ok {
        $is_transferable = $logic_boxes->is_domain_transferable( 'google.com' );
    } 'Lives through checking if domain is transferable';

    ok( $is_transferable, 'Domain is transferable' );
};

done_testing;
