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

subtest 'Renew Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->renew_domain(
            id    => 999999999,
            years => 1,
        );
    } qr/No such domain/, 'Throws on domain that does not exist';
};

subtest 'Renew Deleted Domain' => sub {
    my $domain = create_domain();

    lives_ok {
        $logic_boxes->delete_domain_registration_by_id( $domain->id );
    } 'Lives through deleting domain';

    note( 'Waiting for LogicBoxes to delete domain' );
    sleep 10;

    throws_ok {
        $logic_boxes->renew_domain(
            id    => $domain->id,
            years => 1,
        );
    } qr/Domain is already deleted/, 'Throws on deleted domain';
};

subtest 'Renew Valid Domain' => sub {
    my $domain = create_domain(
        years => 1
    );

    lives_ok {
        $logic_boxes->renew_domain(
            id    => $domain->id,
            years => 1,
        );
    } 'Lives through renewing domain';

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

    cmp_ok( $retrieved_domain->expiration_date->year, '==', DateTime->now->add( years => 2 )->year, 'Correct expiration_date' );
};

subtest 'Renew Domain Past Max Registration Length' => sub {
    my $domain = create_domain(
        years => 5,
    );

    throws_ok {
        $logic_boxes->renew_domain(
            id    => $domain->id,
            years => 8,
        );
    } qr/Unable to renew, would violate max registration length/, 'Throws on Renewal Past Max Duration';
};

done_testing;
