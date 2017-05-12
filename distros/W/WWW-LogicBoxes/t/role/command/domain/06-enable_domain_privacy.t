#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

my $logic_boxes = create_api();

subtest 'Enable Domain Privacy on Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->enable_domain_privacy(
            id => 999999999
        );
    } qr/No such domain/, 'Throws on domain that does not exist';
};

subtest 'Enable Domain Privacy - Domain Already Has Domain Privacy' => sub {
    my $domain = create_domain( is_private => 1 );

    lives_ok {
        $logic_boxes->enable_domain_privacy(
            id => $domain->id
        );
    } 'Lives through enabling domain privacy';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

    ok( $retrieved_domain->is_private, 'Domain is correctly private' );
};

subtest 'Enable Domain Privacy - Domain Purchased Without Domain Privacy' => sub {
    my $domain = create_domain( is_private => 0 );

    lives_ok {
        $logic_boxes->enable_domain_privacy(
            id => $domain->id
        );
    } 'Lives through enabling domain privacy';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

    ok( $retrieved_domain->is_private, 'Domain is correctly private' );
};

subtest 'Enable Domain Privacy - Domain Has Domain Privacy Disabled' => sub {
    my $domain = create_domain( is_private => 1 );

    subtest 'Disable Domain Privacy' => sub {
        lives_ok {
            $logic_boxes->disable_domain_privacy(
                id => $domain->id
            );
        } 'Lives through enabling domain privacy';

        my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

        ok( !$retrieved_domain->is_private, 'Domain is correctly not private' );
    };

    subtest 'Enable Domain Privacy' => sub {
        lives_ok {
            $logic_boxes->enable_domain_privacy(
                id => $domain->id
            );
        } 'Lives through enabling domain privacy';

        my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

        ok( $retrieved_domain->is_private, 'Domain is correctly private' );
    };
};

done_testing;
