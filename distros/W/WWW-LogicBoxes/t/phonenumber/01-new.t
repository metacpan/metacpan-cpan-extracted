#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::LogicBoxes::PhoneNumber;

use Number::Phone;

subtest 'Construct From String' => sub {
    my $phone_number;
    lives_ok {
        $phone_number = WWW::LogicBoxes::PhoneNumber->new( '+18005551212' );
    } 'Lives through new';

    cmp_ok( $phone_number->country_code, 'eq', 1, 'Correct country code' );
    cmp_ok( $phone_number->number, 'eq', '8005551212', 'Correct number' );
    cmp_ok( $phone_number, 'eq', '18005551212', 'Correct String' );
};

subtest 'Construct From Number::Phone' => sub {
    my $number_phone = Number::Phone->new( '+18005551212' );

    my $phone_number;
    lives_ok {
        $phone_number = WWW::LogicBoxes::PhoneNumber->new( $number_phone );
    } 'Lives through new';

    cmp_ok( $phone_number->country_code, 'eq', 1, 'Correct country code' );
    cmp_ok( $phone_number->number, 'eq', '8005551212', 'Correct number' );
    cmp_ok( $phone_number, 'eq', '18005551212', 'Correct String' );
};

subtest 'Construct From Attributes' => sub {
    my $number_phone = Number::Phone->new( '+18005551212' );

    my $phone_number;
    lives_ok {
        $phone_number = WWW::LogicBoxes::PhoneNumber->new( _number_phone_obj => $number_phone );
    } 'Lives through new';

    cmp_ok( $phone_number->country_code, 'eq', 1, 'Correct country code' );
    cmp_ok( $phone_number->number, 'eq', '8005551212', 'Correct number' );
    cmp_ok( $phone_number, 'eq', '18005551212', 'Correct String' );
};

done_testing;
