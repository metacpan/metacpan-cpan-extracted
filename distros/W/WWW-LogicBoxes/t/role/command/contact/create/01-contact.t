#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );
use Storable qw( dclone );
use MooseX::Params::Validate;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );

use WWW::LogicBoxes::Types qw( HashRef );

use WWW::LogicBoxes::Contact;

my $DEFAULT_CONTACT = {
    name         => 'Edsger Dijkstra',
    company      => 'University of Texas at Austin',
    email        => 'POPULATED IN TEST',
    address1     => 'University of Texas',
    address2     => 'Depth First Search Office',
    address3     => 'PO Box 7216',
    city         => 'POPULATED IN TEST',
    state        => 'POPULATED IN TEST',
    country      => 'POPULATED IN TEST',
    zipcode      => 'POPULATED IN TEST',
    phone_number => 'POPULATED IN TEST',
    fax_number   => 'POPULATED IN TEST',
    customer_id  => 'POPULATED IN TEST',
    type         => 'Contact',
};

my $api = create_api( );
my $customer = create_customer( );

subtest 'Create a Minimal US Contact' => sub {
    my $contact_creation_args = dclone $DEFAULT_CONTACT;
    $contact_creation_args->{customer_id}  = $customer->id;

    delete $contact_creation_args->{address2};
    delete $contact_creation_args->{address3};

    $contact_creation_args->{city}     = 'Austin';
    $contact_creation_args->{state}    = 'Texas';
    $contact_creation_args->{country}  = 'US';
    $contact_creation_args->{zipcode}  = '78713';

    $contact_creation_args->{phone_number} = '15124757575';
    delete $contact_creation_args->{fax_number};

    test_contact_creation( $contact_creation_args );
};

subtest 'Create a Full US Contact' => sub {
    my $contact_creation_args = dclone $DEFAULT_CONTACT;
    $contact_creation_args->{customer_id}  = $customer->id;

    $contact_creation_args->{city}     = 'Austin';
    $contact_creation_args->{state}    = 'Texas';
    $contact_creation_args->{country}  = 'US';
    $contact_creation_args->{zipcode}  = '78713';

    $contact_creation_args->{phone_number} = '15124757575';
    $contact_creation_args->{fax_number}   = '15124757515';

    test_contact_creation( $contact_creation_args );
};

subtest 'Create a Full CA Contact' => sub {
    my $contact_creation_args = dclone $DEFAULT_CONTACT;
    $contact_creation_args->{customer_id}  = $customer->id;

    $contact_creation_args->{city}         = 'Toronto';
    $contact_creation_args->{state}        = 'Ontario';
    $contact_creation_args->{country}      = 'CA';
    $contact_creation_args->{zipcode}      = 'M5G 1S4';

    $contact_creation_args->{phone_number} = Number::Phone->new( '14162014056' );
    $contact_creation_args->{fax_number}   = Number::Phone->new( '14186922095' );

    test_contact_creation( $contact_creation_args );
};

subtest 'Create a Full GB Contact' => sub {
    my $contact_creation_args = dclone $DEFAULT_CONTACT;
    $contact_creation_args->{customer_id}  = $customer->id;

    $contact_creation_args->{city}         = 'London';
    delete $contact_creation_args->{state};
    $contact_creation_args->{country}      = 'GB';
    $contact_creation_args->{zipcode}      = 'W1A 2LQ';

    $contact_creation_args->{phone_number} = Number::Phone->new( '442074999000' );
    $contact_creation_args->{fax_number}   = Number::Phone->new( '442890681301' );

    test_contact_creation( $contact_creation_args );
};

subtest 'Create a Full Scotland Contact' => sub {
    my $contact_creation_args = dclone $DEFAULT_CONTACT;
    $contact_creation_args->{customer_id}  = $customer->id;

    $contact_creation_args->{city}         = 'Edinburgh';
    $contact_creation_args->{state}        = 'Scotland';
    $contact_creation_args->{country}      = 'GB';
    $contact_creation_args->{zipcode}      = 'EH7 5BW';

    $contact_creation_args->{phone_number} = Number::Phone->new( '441315568315' );
    $contact_creation_args->{fax_number}   = Number::Phone->new( '441315576023' );

    test_contact_creation( $contact_creation_args );
};

subtest 'Create a Full DE Contact' => sub {
    my $contact_creation_args = dclone $DEFAULT_CONTACT;
    $contact_creation_args->{customer_id}  = $customer->id;

    $contact_creation_args->{city}         = 'Berlin';
    delete $contact_creation_args->{state};
    $contact_creation_args->{country}      = 'DE';
    $contact_creation_args->{zipcode}      = '14191';

    $contact_creation_args->{phone_number} = Number::Phone->new( '+49-30-8305-0' );
    $contact_creation_args->{fax_number}   = Number::Phone->new( '+49-30-8305-1215' );

    test_contact_creation( $contact_creation_args );
};

subtest 'Create a Full ZA Contact' => sub {
    my $contact_creation_args = dclone $DEFAULT_CONTACT;
    $contact_creation_args->{customer_id}  = $customer->id;

    $contact_creation_args->{city}         = 'Westlake';
    delete $contact_creation_args->{state};
    $contact_creation_args->{country}      = 'ZA';
    $contact_creation_args->{zipcode}      = '7945';

    $contact_creation_args->{phone_number} = Number::Phone->new( '+27-11-290-3000' );
    $contact_creation_args->{fax_number}   = Number::Phone->new( '+27-27-111-0391' );

    test_contact_creation( $contact_creation_args );
};

done_testing;

sub test_contact_creation {
    my ( $contact_creation_args ) = pos_validated_list( \@_, { isa => HashRef } );

    $contact_creation_args->{email} = 'test-' . random_string('nnccnnccnnccnnccnnccnncc') . '@testing.com';

    my $contact;
    lives_ok {
        $contact = WWW::LogicBoxes::Contact->new( $contact_creation_args );
    } 'Lives through contact object creation';

    my $created_contact;
    lives_ok {
        $created_contact = $api->create_contact({ contact => $contact });
    } 'Lives through remote contact creation';

    ok( $created_contact->has_id, "An id has been set" );
    like( $created_contact->id, qr/^\d+$/, "The id is numeric" );

    my $retrieved_contact;
    subtest 'Inspect Created Contact' => sub {
        note("Contact ID: " . $created_contact->id);

        lives_ok {
            $retrieved_contact = $api->get_contact_by_id( $created_contact->id );
        } "Lives through fetching a contact";

        if( isa_ok($retrieved_contact, "WWW::LogicBoxes::Contact") ) {
            subtest 'Basic Fields' => sub {
                cmp_ok( $retrieved_contact->name,        'eq', $contact_creation_args->{name}, 'Correct name' );
                cmp_ok( $retrieved_contact->company,     'eq', $contact_creation_args->{company}, 'Correct company' );
                cmp_ok( $retrieved_contact->email,       'eq', $contact_creation_args->{email}, 'Correct email' );
                cmp_ok( $retrieved_contact->type,        'eq', $contact_creation_args->{type}, 'Correct type' );
                cmp_ok( $retrieved_contact->customer_id, '==', $contact_creation_args->{customer_id}, 'Correct owner_id' );
            };

            subtest 'Address Fields' => sub {
                cmp_ok( $retrieved_contact->address1,  'eq', $contact_creation_args->{address1}, 'Correct address1' );

                for my $address_field (qw( address2 address3 )) {
                    if( exists $contact_creation_args->{$address_field} ) {
                        cmp_ok( $retrieved_contact->$address_field, 'eq',
                            $contact_creation_args->{$address_field}, "Correct $address_field" );
                    }
                    else {
                        my $predicate = "has_$address_field";
                        ok( !$retrieved_contact->$predicate, "Correctly lacks $address_field" );
                    }
                }
            };

            subtest 'Region Related Fields' => sub {
                cmp_ok( $retrieved_contact->city, 'eq', $contact_creation_args->{city}, 'Correct city' );

                if( exists $contact_creation_args->{state} ) {
                    cmp_ok( $retrieved_contact->state, 'eq', $contact_creation_args->{state}, 'Correct state' );
                }
                else {
                    ok( !$retrieved_contact->has_state, 'Correctly lacks state' );
                }

                cmp_ok( $retrieved_contact->country, 'eq', $contact_creation_args->{country}, 'Correct country' );
                cmp_ok( $retrieved_contact->zipcode, 'eq', $contact_creation_args->{zipcode}, 'Correct zipcode' );
            };

            subtest 'Phone Number Fields' => sub {
                cmp_ok($retrieved_contact->phone_number, 'eq', $contact->phone_number, 'Correct phone_number');

                if( exists $contact_creation_args->{fax_number} ) {
                    cmp_ok($retrieved_contact->fax_number, 'eq', $contact->fax_number, 'Correct fax_number');
                }
                else {
                    ok( !$retrieved_contact->has_fax_number, 'Correctly lacks fax_number' );
                }
            };
        }
    };
}
