#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );
use Test::WWW::LogicBoxes::Contact qw( create_contact );

use WWW::LogicBoxes::Contact;

my $logic_boxes = create_api();

subtest 'Get Contact By ID That Does Not Exist' => sub {
    my $retrieved_contact;
    lives_ok {
        $retrieved_contact = $logic_boxes->get_contact_by_id( 9999999999 );
    } 'Lives through retrieving_contact';

    ok( !defined $retrieved_contact, 'Correctly does not return a contact' );
};

subtest 'Get Valid Contact By ID' => sub {
    my $contact = create_contact();

    my $retrieved_contact;
    lives_ok {
        $retrieved_contact = $logic_boxes->get_contact_by_id( $contact->id );
    } 'Lives through retrieving contact';

    is_deeply( $retrieved_contact, $contact, 'Correct contact' );
};

subtest 'Get a Contact With Duplicate Country Code Phone Number' => sub {
    my $customer = create_customer();

    # There is no way to create a bad contact like this using the library
    # since the library protects against it.  Use submit directly in order to force
    # the bad contact to get created.
    my $contact_creation_response = $logic_boxes->submit({
        method => 'contacts__add',
        params => {
            name             => 'Anita Borg',
            company          => 'Grace Hopper Celebration of Women in Computing',
            email            => 'anita.borg@dec.com',
            'address-line-1' => '1501 Page Mill Road',
            city             => 'Palo Alto',
            state            => 'CA',
            country          => 'US',
            zipcode          => '94304',
            'phone-cc'       => '1',
            phone            => '16508571501',
            type             => 'Contact',
            'customer-id'    => $customer->id,
        }
    });

    my $retrieved_contact;
    lives_ok {
        $retrieved_contact = $logic_boxes->get_contact_by_id( $contact_creation_response->{id} );
    } 'Lives through retrieving contact';

    cmp_ok( $retrieved_contact->phone_number, 'eq', '16508571501', 'Correct phone_number' );
};

done_testing;
