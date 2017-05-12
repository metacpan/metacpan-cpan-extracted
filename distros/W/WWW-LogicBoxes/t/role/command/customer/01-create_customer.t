#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );
use Storable qw( dclone );
use MooseX::Params::Validate;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw(create_api);

use WWW::LogicBoxes::Types qw( HashRef );

use WWW::LogicBoxes::Customer;

use WWW::LogicBoxes::PhoneNumber;
use Number::Phone;

my $DEFAULT_CUSTOMER = {
    username => 'POPULATED IN TEST',
    name     => 'Alan Turing',
    company  => 'Princeton University',
    address1 => '123 Turing Machine Way',
    address2 => 'Office P is equal to NP',
    address3 => 'Office P is not equal to NP',
    city     => 'POPULATED IN TEST',
    state    => 'POPULATED IN TEST',
    country  => 'POPULATED IN TEST',
    zipcode  => 'POPULATED IN TEST',
    phone_number        => 'POPULATED IN TEST',
    alt_phone_number    => 'POPULATED IN TEST',
    mobile_phone_number => 'POPULATED IN TEST',
    fax_number          => 'POPULATED IN TEST',
};

my $logic_boxes = create_api();

subtest 'Create a Minimal US Customer' => sub {
    my $customer_creation_args = dclone $DEFAULT_CUSTOMER;
    $customer_creation_args->{city}     = 'Princeton';
    $customer_creation_args->{state}    = 'New Jersey';
    $customer_creation_args->{country}  = 'US';
    $customer_creation_args->{zipcode}  = '08544';

    delete $customer_creation_args->{address2};
    delete $customer_creation_args->{address3};

    $customer_creation_args->{phone_number}= Number::Phone->new( '16092583000' );
    delete $customer_creation_args->{alt_phone_number};
    delete $customer_creation_args->{mobile_phone_number};
    delete $customer_creation_args->{fax_number};

    test_customer_creation( $customer_creation_args );
};

subtest 'Create a Full US Customer' => sub {
    my $customer_creation_args = dclone $DEFAULT_CUSTOMER;
    $customer_creation_args->{city}     = 'Princeton';
    $customer_creation_args->{state}    = 'New Jersey';
    $customer_creation_args->{country}  = 'US';
    $customer_creation_args->{zipcode}  = '08544';

    $customer_creation_args->{phone_number}        = Number::Phone->new( '16092583000' );
    $customer_creation_args->{alt_phone_number}    = Number::Phone->new( '16092583020' );
    $customer_creation_args->{mobile_phone_number} = Number::Phone->new( '16092583040' );
    $customer_creation_args->{fax_number}          = Number::Phone->new( '16092582255' );

    test_customer_creation( $customer_creation_args );
};

subtest 'Create a Full CA Customer' => sub {
    my $customer_creation_args = dclone $DEFAULT_CUSTOMER;
    $customer_creation_args->{city}     = 'Toronto';
    $customer_creation_args->{state}    = 'Ontario';
    $customer_creation_args->{country}  = 'CA';
    $customer_creation_args->{zipcode}  = 'M5G 1S4';

    $customer_creation_args->{phone_number}        = Number::Phone->new( '14162014056' );
    $customer_creation_args->{alt_phone_number}    = Number::Phone->new( '14032668962' );
    $customer_creation_args->{mobile_phone_number} = Number::Phone->new( '15143989695' );
    $customer_creation_args->{fax_number}          = Number::Phone->new( '14186922095' );

    test_customer_creation( $customer_creation_args );
};

subtest 'Create a Full GB Customer' => sub {
    my $customer_creation_args = dclone $DEFAULT_CUSTOMER;
    $customer_creation_args->{city}     = 'London';
    delete $customer_creation_args->{state};
    $customer_creation_args->{country}  = 'GB';
    $customer_creation_args->{zipcode}  = 'W1A 2LQ';

    $customer_creation_args->{phone_number}        = Number::Phone->new( '442074999000' );
    $customer_creation_args->{alt_phone_number}    = Number::Phone->new( '442074955012' );
    $customer_creation_args->{mobile_phone_number} = Number::Phone->new( '442890386100' );
    $customer_creation_args->{fax_number}          = Number::Phone->new( '442890681301' );

    test_customer_creation( $customer_creation_args );
};

subtest 'Create a Full Scotland Customer' => sub {
    my $customer_creation_args = dclone $DEFAULT_CUSTOMER;
    $customer_creation_args->{city}     = 'Edinburgh';
    $customer_creation_args->{state}    = 'Scotland';
    $customer_creation_args->{country}  = 'GB';
    $customer_creation_args->{zipcode}  = 'EH7 5BW';

    $customer_creation_args->{phone_number}        = Number::Phone->new( '441315568315' );
    $customer_creation_args->{alt_phone_number}    = Number::Phone->new( '442920026419' );
    $customer_creation_args->{mobile_phone_number} = Number::Phone->new( '442074999000' );
    $customer_creation_args->{fax_number}          = Number::Phone->new( '441315576023' );

    test_customer_creation( $customer_creation_args );
};

subtest 'Create a Full DE Customer' => sub {
    my $customer_creation_args = dclone $DEFAULT_CUSTOMER;
    $customer_creation_args->{city}     = 'Berlin';
    delete $customer_creation_args->{state};
    $customer_creation_args->{country}  = 'DE';
    $customer_creation_args->{zipcode}  = '14191';

    $customer_creation_args->{phone_number}        = Number::Phone->new( '+49-30-8305-0' );
    $customer_creation_args->{alt_phone_number}    = Number::Phone->new( '+49-69-7535-2100' );
    $customer_creation_args->{mobile_phone_number} = Number::Phone->new( '+49-30-8305-0' );
    $customer_creation_args->{fax_number}          = Number::Phone->new( '+49-30-8305-1215' );

    test_customer_creation( $customer_creation_args );
};

subtest 'Create a Full ZA Customer' => sub {
    my $customer_creation_args = dclone $DEFAULT_CUSTOMER;
    $customer_creation_args->{city}     = 'Westlake';
    delete $customer_creation_args->{state};
    $customer_creation_args->{country}  = 'ZA';
    $customer_creation_args->{zipcode}  = '7945';

    $customer_creation_args->{phone_number}        = Number::Phone->new( '+27-11-290-3000' );
    $customer_creation_args->{alt_phone_number}    = Number::Phone->new( '+27-79-111-1684'  );
    $customer_creation_args->{mobile_phone_number} = Number::Phone->new( '+27-21-702-7300' );
    $customer_creation_args->{fax_number}          = Number::Phone->new( '+27-27-111-0391' );

    test_customer_creation( $customer_creation_args );
};

done_testing;

sub test_customer_creation {
    my ( $customer_creation_args ) = pos_validated_list( \@_, { isa => HashRef } );

    $customer_creation_args->{username} = 'test-' . random_string('ccnnccnnccnnccnn') . '@testing.com';

    my $customer;
    lives_ok {
        $customer = WWW::LogicBoxes::Customer->new( $customer_creation_args );
    } "Lives through customer object creation";

    my $created_customer;
    lives_ok {
        $created_customer = $logic_boxes->create_customer({
            customer => $customer,
            password => random_string('ccnnccnnccnn'),
        });
    } "Lives through remote customer creation";

    isa_ok( $created_customer, 'WWW::LogicBoxes::Customer' );
    ok($created_customer->has_id, "An id has been set");
    like($created_customer->id, qr/^\d+$/, "The id is numeric");

    my $retrieved_customer;
    subtest 'Inspect Created Customer' => sub {
        note("Customer ID: " . $created_customer->id);

        lives_ok {
            $retrieved_customer = $logic_boxes->get_customer_by_id( $created_customer->id );
        } 'Lives through retrieving customer';

        if( isa_ok($retrieved_customer, 'WWW::LogicBoxes::Customer') ) {
            subtest 'Basic Fields' => sub {
                cmp_ok( $retrieved_customer->id,        '==', $created_customer->id, "Correct id"       );
                cmp_ok( $retrieved_customer->name,      'eq', $customer->name,       "Correct name"     );
                cmp_ok( $retrieved_customer->company,   'eq', $customer->company,    "Correct company"  );
                cmp_ok( $retrieved_customer->username,  'eq', $customer->username,   "Correct username" );
                cmp_ok( $retrieved_customer->language_preference, 'eq',
                    $customer->language_preference, "Correct language_preference" );
            };

            subtest 'Address Fields' => sub {
                cmp_ok( $retrieved_customer->address1, 'eq', $customer->address1, "Correct address1" );

                for my $address_field (qw( address2 address3 )) {
                    if( exists $customer_creation_args->{$address_field} ) {
                        cmp_ok( $retrieved_customer->$address_field, 'eq', $customer->$address_field, "Correct $address_field" );
                    }
                    else {
                        my $predicate = "has_$address_field";
                        ok( !$retrieved_customer->$predicate, "Correctly lacks $address_field" );
                    }
                }
            };

            subtest 'Region Related Fields' => sub {
                cmp_ok( $retrieved_customer->city, 'eq', $customer_creation_args->{city}, "Correct city" );

                if( exists $customer_creation_args->{state} ) {
                    cmp_ok( $retrieved_customer->state, 'eq', $customer_creation_args->{state}, "Correct state" );
                }
                else {
                    ok( !$retrieved_customer->has_state, 'Correctly Lacks State' );
                }

                cmp_ok( $retrieved_customer->country, 'eq', $customer_creation_args->{country}, "Correct country" );
                cmp_ok( $retrieved_customer->zipcode, 'eq', $customer_creation_args->{zipcode}, "Correct zipcode" );
            };

            subtest 'Phone Number Fields' => sub {
                cmp_ok( $retrieved_customer->phone_number,
                    'eq', $customer->phone_number, "Correct phone_number" );

                for my $number_field (qw( fax_number alt_phone_number )) {
                    if( exists $customer_creation_args->{$number_field} ) {
                        cmp_ok( $retrieved_customer->$number_field,
                            'eq', $customer->$number_field, "Correct $number_field" );
                    }
                    else {
                        my $predicate = "has_$number_field";
                        ok( !$retrieved_customer->$predicate, "Correctly lacks $number_field" );
                    }
                }

                # This exists due to a bug with LogicBoxes using the phone_number as the mobile_phone_number
                # if no mobile_phone_number is specified
                my $number_field = 'mobile_phone_number';
                if( exists $customer_creation_args->{$number_field} ) {
                    cmp_ok( $retrieved_customer->$number_field,
                        'eq', $customer->$number_field, "Correct $number_field" );
                }
                else {
                    TODO: {
                        local $TODO = 'LogicBoxes Has an Issue of using the phone_number as the mobile_phone_number';

                        my $predicate = "has_$number_field";
                        ok( !$retrieved_customer->$predicate, "Correctly lacks $number_field" );
                    };
                }
            };
        }
    };

    return $retrieved_customer;
};
