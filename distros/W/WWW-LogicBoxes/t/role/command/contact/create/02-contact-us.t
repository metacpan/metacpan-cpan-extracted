#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );

use WWW::LogicBoxes::Contact::US;

subtest 'Create .US Contact' => sub {
    my $api      = create_api();
    my $customer = create_customer();

    my $nexus_purpose  = 'P1';
    my $nexus_category = 'C11';

    my $contact;
    lives_ok {
        $contact = WWW::LogicBoxes::Contact::US->new(
            name           => 'Edsger Dijkstra',
            company        => 'University of Texas at Austin',
            email          => 'test-' . random_string('ccnnccnnccnnccnnccnnccnn') . '@testing.com',
            address1       => 'University of Texas',
            city           => 'Austin',
            state          => 'Texas',
            country        => 'US',
            zipcode        => '78713',
            phone_number   => '15124757575',
            customer_id    => $customer->id,
            nexus_purpose  => $nexus_purpose,
            nexus_category => $nexus_category,
        );
    } 'Lives through contact object creation';

    my $created_contact;
    lives_ok {
        $created_contact = $api->create_contact( contact => $contact );
    } 'Lives through contact creation';

    subtest 'Inspect US Specific Attributes' => sub {
        my $retrieved_contact;
        lives_ok {
            $retrieved_contact = $api->get_contact_by_id( $contact->id );
        } 'Lives through fetching contact';

        if( isa_ok( $retrieved_contact, 'WWW::LogicBoxes::Contact::US' ) ) {
            note( 'Contact ID: ' . $retrieved_contact->id );

            cmp_ok( $retrieved_contact->nexus_purpose, 'eq', $nexus_purpose, 'Correct nexus_purpose' );
            cmp_ok( $retrieved_contact->nexus_category, 'eq', $nexus_category, 'Correct nexus_category' );
        }
    };
};

done_testing;
