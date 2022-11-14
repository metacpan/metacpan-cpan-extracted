#!/usr/bin/perl

use strict;
use warnings;
use WebService::MyAffiliates;
use Test::More;
use Test::Exception;
use Test::MockModule;

my $aff = WebService::MyAffiliates->new(
    user => 'user',
    pass => 'pass',
    host => 'host'
);

my $mock_aff = Test::MockModule->new('WebService::MyAffiliates');

$mock_aff->mock(
    'request',
    sub {
        return +{
            'INIT' => {
                'ERROR_COUNT'   => 0,
                'WARNING_COUNT' => 0,
            }};

    });

ok($aff->create_affiliate({}), 'A hashref is a valid parameter');

my $hash_params = (first_name => 'Dummy');

ok($aff->create_affiliate({}), 'A hash is a valid parameter');

$mock_aff->mock(
    'request',
    sub {
        return +{
            'INIT' => {
                'ERROR_COUNT' => 1,
                'ERROR'       => {
                    'MSG'    => 'An account with this email already exists.',
                    'DETAIL' => 'email'
                }}};

    });

my $args = {
    'first_name'    => 'Charles',
    'last_name'     => 'Babbage',
    'date_of_birth' => '1871-10-18',
    'individual'    => 'individual',
    'phone_number'  => '+4412341234',
    'address'       => 'Some street',
    'city'          => 'Some City',
    'state'         => 'Some State',
    'postcode'      => '1234',
    'website'       => 'https://www.example.com/',
    'agreement'     => 1,
    'username'      => 'charles_babbage',
    'email'         => 'repeated@email.com',
    'country'       => 'GB',
    'password'      => 's3cr3t',
    'plans'         => '2,4',
};

my $res = $aff->create_affiliate($args);

ok(!$res, 'Returns undef in case of a single error');

$mock_aff->mock(
    'request',
    sub {
        return +{
            'INIT' => {
                'ERROR_COUNT' => 2,
                'ERROR'       => [{
                        'MSG'    => 'An account with this email already exists.',
                        'DETAIL' => 'email'
                    },
                    {
                        'DETAIL' => 'username',
                        'MSG'    => 'Username not available'
                    }]}};

    });

$res = $aff->create_affiliate($args);

ok(!$res, 'Returns undef in case of multiple errors');

$mock_aff->mock(
    'request',
    sub {
        return +{
            'INIT' => {
                'ERROR_COUNT' => 2,
                'ERROR'       => {
                    'MSG'    => 'An account with this email already exists.',
                    'DETAIL' => 'email'
                }}};

    });

$res = $aff->create_affiliate($args);

ok(!$res, 'Returns undef in case of single error');

$mock_aff->mock(
    'request',
    sub {
        return +{
            'INIT' => {
                'ERROR_COUNT'    => 0,
                'WARNING_COUNT'  => 1,
                'WARNING_DETAIL' => {
                    'DETAIL' => 'password',
                    'MSG'    => 'Setting a password for a new affiliate is optional and will be deprecated in future'
                },
                'USERNAME' => 'charles_babbage',
                'PASSWORD' => 's3cr3t',
                'PARENT'   => 0,
                'USERID'   => 170890,
                'COUNTRY'  => 'GB',
                'LANGUAGE' => 0,
                'EMAIL'    => 'repeated@email.com'
            }};
    });

$res = $aff->create_affiliate($args);

ok($res,              'Returns the ref correctly');
ok(!$res->{PASSWORD}, 'It does not return the password');

done_testing();

1;
