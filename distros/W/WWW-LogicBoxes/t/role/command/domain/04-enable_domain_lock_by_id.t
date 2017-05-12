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

subtest 'Lock Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->enable_domain_lock_by_id( 999999999 );
    } qr/No such domain/, 'Throws enabling domain lock on domain that does not exist';
};

subtest 'Lock Domain That Is Already Locked' => sub {
    my $domain = create_domain();

    lives_ok {
        $logic_boxes->enable_domain_lock_by_id( $domain->id );
    } 'Lives through locking domain';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
    ok( $retrieved_domain->is_locked, 'Domain is locked' );
};

subtest 'Lock Domain That Is Not Locked' => sub {
    my $domain = create_domain();

    subtest 'Unlock domain' => sub {
        lives_ok {
            $logic_boxes->disable_domain_lock_by_id( $domain->id );
        } 'Lives through unlocking domain';

        my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
        ok( !$retrieved_domain->is_locked, 'Domain is not locked' );
    };

    subtest 'Lock Domain' => sub {
        lives_ok {
            $logic_boxes->enable_domain_lock_by_id( $domain->id );
        } 'Lives through locking domain';

        my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
        ok( $retrieved_domain->is_locked, 'Domain is locked' );
    }
};


done_testing;
