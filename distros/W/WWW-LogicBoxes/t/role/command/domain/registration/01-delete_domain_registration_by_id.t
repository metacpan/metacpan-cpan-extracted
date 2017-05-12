#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

use WWW::LogicBoxes::Domain;

my $logic_boxes = create_api();

subtest 'Delete a Domain Registration That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->delete_domain_registration_by_id( 999999999 );
    } qr/No such domain to delete/, 'Throws on deleting a domain registration that does not exist';
};

subtest 'Delete Valid Domain Registration' => sub {
    my $domain = create_domain();

    lives_ok {
        $logic_boxes->delete_domain_registration_by_id( $domain->id );
    } 'Lives through domain registration deletion';

    subtest 'Retrieve Domain Right Away' => sub {
        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
        } 'Lives through retrieving domain by id';

        isa_ok( $retrieved_domain, 'WWW::LogicBoxes::Domain' );
    };

    note( 'Waiting for LogicBoxes to delete domain' );
    sleep 10;

    subtest 'Retrieve Deleted Domain' => sub {
        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
        } 'Lives through retrieving domain by id';

        cmp_ok( $retrieved_domain->status, 'eq', 'Deleted', 'Correct Status' );
    };

    subtest 'Retrieve Deleted Domain - Missing raaVerificationStatus' => sub {
        my $mocked_domain = Test::MockModule->new('WWW::LogicBoxes::Domain');
        $mocked_domain->mock( 'construct_from_response', sub {
            my $self     = shift;
            my $response = shift;

            delete $response->{raaVerificationStatus};
            return $mocked_domain->original('construct_from_response')->( $self, $response );
        });

        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
        } 'Lives through retrieving domain by id';

        cmp_ok( $retrieved_domain->status, 'eq', 'Deleted', 'Correct Status' );
        cmp_ok( $retrieved_domain->verification_status, 'eq', 'NA', 'Correct verification_status' );
    };
};

done_testing;
