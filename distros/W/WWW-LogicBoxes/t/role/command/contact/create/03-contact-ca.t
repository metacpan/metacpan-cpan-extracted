#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );

use WWW::LogicBoxes::Types qw( CPR CPRIndividual CPRNonIndividual Int Str );

use WWW::LogicBoxes::Contact::CA;

my $api       = create_api();
my $customer  = create_customer();
my $agreement = $api->get_ca_registrant_agreement();

subtest 'Create .CA Contact - Individual' => sub {
    for my $cpr (@{ CPRIndividual->values }) {
        test_ca_contact_creation(
            customer_id       => $customer->id,
            name              => 'Edsger Dijkstra',
            company           => 'University of Texas at Austin',
            cpr               => $cpr,
            agreement_version => $agreement->version,
        );
    }
};

subtest 'Create .CA Contact - Non Individual' => sub {
    for my $cpr (@{ CPRNonIndividual->values }) {
        test_ca_contact_creation(
            customer_id       => $customer->id,
            name              => 'Bank Of ICANN',
            company           => 'N/A',
            cpr               => $cpr,
            agreement_version => $agreement->version,
        );
    }
};

done_testing;

sub test_ca_contact_creation {
    my ( %args ) = validated_hash(
        \@_,
        customer_id       => { isa => Int },
        name              => { isa => Str },
        company           => { isa => Str },
        cpr               => { isa => CPR },
        agreement_version => { isa => Str },
    );

    my $contact;
    subtest $args{cpr} => sub {
        lives_ok {
            $contact = WWW::LogicBoxes::Contact::CA->new(
                name           => $args{name},
                company        => $args{company},
                email          => 'test-' . random_string('ccnnccnnccnnccnnccnnccnn') . '@testing.com',
                address1       => 'University of Texas',
                city           => 'Austin',
                state          => 'Texas',
                country        => 'US',
                zipcode        => '78713',
                phone_number   => '15124757575',
                customer_id    => $args{customer_id},

                agreement_version => $args{agreement_version},
                cpr               => $args{cpr},
            );
        } 'Lives through contact object creation';

        my $created_contact;
        lives_ok {
            $created_contact = $api->create_contact( contact => $contact );
        } 'Lives through contact creation';

        subtest 'Inspect CA Specific Attributes' => sub {
            my $retrieved_contact;
            lives_ok {
                $retrieved_contact = $api->get_contact_by_id( $contact->id );
            } 'Lives through fetching contact';

            if( isa_ok( $retrieved_contact, 'WWW::LogicBoxes::Contact::CA' ) ) {
                note( 'Contact ID: ' . $retrieved_contact->id );

                cmp_ok( $retrieved_contact->type, 'eq', 'CaContact', 'Correct type' );
                cmp_ok( $retrieved_contact->cpr,  'eq', $args{cpr},  'Correct cpr' );

                # Agreement Version is not Returned when retrieving a contact
                ok( !$retrieved_contact->has_agreement_version, 'Correctly lacks agreement version' );
            }
        };
    };

    return $contact;
}

