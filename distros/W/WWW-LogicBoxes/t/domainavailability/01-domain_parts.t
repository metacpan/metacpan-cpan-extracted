#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::LogicBoxes::DomainAvailability;

subtest 'Parse domain.com' => sub {
    my $domain_availability = WWW::LogicBoxes::DomainAvailability->new(
        name         => 'domain.com',
        is_available => 0,
    );

    lives_ok {
        cmp_ok( $domain_availability->sld, 'eq', 'domain', 'Correct sld' );
        cmp_ok( $domain_availability->tld, 'eq', 'com', 'Correct tld' );
        cmp_ok( $domain_availability->public_suffix, 'eq', 'com', 'Correct public_suffix' );
    } 'Lives through extracting sld';
};

subtest 'Parse domain.co.uk' => sub {
    my $domain_availability = WWW::LogicBoxes::DomainAvailability->new(
        name         => 'domain.co.uk',
        is_available => 0,
    );

    lives_ok {
        cmp_ok( $domain_availability->sld, 'eq', 'domain', 'Correct sld' );
        cmp_ok( $domain_availability->tld, 'eq', 'co.uk', 'Correct tld' );
        cmp_ok( $domain_availability->public_suffix, 'eq', 'co.uk', 'Correct public_suffix' );
    } 'Lives through extracting sld';
};

subtest 'Parse sub.domain.com' => sub {
    my $domain_availability = WWW::LogicBoxes::DomainAvailability->new(
        name         => 'sub.domain.com',
        is_available => 0,
    );

    lives_ok {
        cmp_ok( $domain_availability->sld, 'eq', 'sub.domain', 'Correct sld' );
        cmp_ok( $domain_availability->tld, 'eq', 'com', 'Correct tld' );
        cmp_ok( $domain_availability->public_suffix, 'eq', 'com', 'Correct public_suffix' );
    } 'Lives through extracting sld';
};

subtest 'Parse sub.domain.co.uk' => sub {
    my $domain_availability = WWW::LogicBoxes::DomainAvailability->new(
        name         => 'sub.domain.co.uk',
        is_available => 0,
    );

    lives_ok {
        cmp_ok( $domain_availability->sld, 'eq', 'sub.domain', 'Correct sld' );
        cmp_ok( $domain_availability->tld, 'eq', 'co.uk', 'Correct tld' );
        cmp_ok( $domain_availability->public_suffix, 'eq', 'co.uk', 'Correct public_suffix' );
    } 'Lives through extracting sld';
};

done_testing;
