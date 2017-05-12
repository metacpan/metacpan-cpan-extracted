#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;
use Moose::Meta::Class;

use WWW::eNom::Types qw( DomainName );

use WWW::eNom::Role::ParseDomain;

subtest 'Parse domain.com' => sub {
    my $test_object = generate_test_object('domain.com');

    lives_ok {
        cmp_ok( $test_object->sld, 'eq', 'domain', 'Correct sld' );
        cmp_ok( $test_object->tld, 'eq', 'com', 'Correct tld' );
        cmp_ok( $test_object->public_suffix, 'eq', 'com', 'Correct public_suffix' );
    } 'Lives through extracting sld';
};

subtest 'Parse domain.co.uk' => sub {
    my $test_object = generate_test_object('domain.co.uk');

    lives_ok {
        cmp_ok( $test_object->sld, 'eq', 'domain', 'Correct sld' );
        cmp_ok( $test_object->tld, 'eq', 'co.uk', 'Correct tld' );
        cmp_ok( $test_object->public_suffix, 'eq', 'co.uk', 'Correct public_suffix' );
    } 'Lives through extracting sld';
};

subtest 'Parse sub.domain.com' => sub {
    my $test_object = generate_test_object('sub.domain.com');

    lives_ok {
        cmp_ok( $test_object->sld, 'eq', 'sub.domain', 'Correct sld' );
        cmp_ok( $test_object->tld, 'eq', 'com', 'Correct tld' );
        cmp_ok( $test_object->public_suffix, 'eq', 'com', 'Correct public_suffix' );
    } 'Lives through extracting sld';
};

subtest 'Parse sub.domain.co.uk' => sub {
    my $test_object = generate_test_object('sub.domain.co.uk');

    lives_ok {
        cmp_ok( $test_object->sld, 'eq', 'sub.domain', 'Correct sld' );
        cmp_ok( $test_object->tld, 'eq', 'co.uk', 'Correct tld' );
        cmp_ok( $test_object->public_suffix, 'eq', 'co.uk', 'Correct public_suffix' );
    } 'Lives through extracting sld';
};

done_testing;

sub generate_test_object {
    my ( $name ) = pos_validated_list( \@_, { isa => DomainName } );

    my $test_class = Moose::Meta::Class->create(
        'Test',
        roles => [ 'WWW::eNom::Role::ParseDomain' ],
        methods => {
            name => sub { return $name }
        }
    );

    return $test_class->new_object;
}
