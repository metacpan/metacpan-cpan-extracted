#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Contact qw( create_contact );

use WWW::eNom::DomainRequest::Registration;

subtest 'Register Available Domain - No Privacy, Locking, Auto Renew' => sub {
    my $eNom = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Registration->new({
            name               => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.com',
            ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
            is_ns_fail_fatal   => 0,
            is_locked          => 0,
            is_private         => 0,
            is_auto_renew      => 0,
            years              => 1,
            is_queueable       => 0,
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        });
    } 'Lives through creating request object';

    my $domain;
    lives_ok {
        $domain = $eNom->register_domain( request => $request );
    } 'Lives through registering domain';

    if( isa_ok( $domain, 'WWW::eNom::Domain' ) ) {
        like( $domain->id, qr/^\d+$/, 'id looks numeric' );
        cmp_ok( $domain->name,                 'eq', $request->name,       'Correct name' );
        cmp_ok( $domain->status,               'eq', 'Registered',         'Correct status' );
        cmp_ok( $domain->verification_status,  'eq', 'Pending Suspension', 'Correct verification_status' );
        cmp_ok( $domain->is_auto_renew,        '==', 0,                    'Correct is_auto_renew' );
        cmp_ok( $domain->is_locked,            '==', 0,                    'Correct is_locked' );
        cmp_ok( $domain->is_private,           '==', 0,                    'Correct is_private' );
        cmp_ok( $domain->created_date->ymd,    'eq', DateTime->now( time_zone => 'UTC' )->ymd, 'Correct created_date' );
        cmp_ok( $domain->expiration_date->ymd, 'eq', DateTime->now( time_zone => 'UTC' )->add( years => 1 )->ymd,
            'Correct expiration_date' );
        is_deeply( $request->ns, $domain->ns, 'Correct nameservers' );

        for my $contact_type (qw( registrant_contact admin_contact technical_contact billing_contact )) {
            is_deeply( $domain->$contact_type, $request->$contact_type, "Correct $contact_type" );
        }
    }
};

subtest 'Register Available Domain - With Privacy, Locking, Auto Renew' => sub {
    my $eNom = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Registration->new({
            name               => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.com',
            ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
            is_ns_fail_fatal   => 0,
            is_locked          => 1,
            is_private         => 1,
            is_auto_renew      => 1,
            years              => 1,
            is_queueable       => 0,
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        });
    } 'Lives through creating request object';

    my $domain;
    lives_ok {
        $domain = $eNom->register_domain( request => $request );
    } 'Lives through registering domain';

    if( isa_ok( $domain, 'WWW::eNom::Domain' ) ) {
        like( $domain->id, qr/^\d+$/, 'id looks numeric' );
        cmp_ok( $domain->name,                 'eq', $request->name,       'Correct name' );
        cmp_ok( $domain->status,               'eq', 'Registered',         'Correct status' );
        cmp_ok( $domain->verification_status,  'eq', 'Pending Suspension', 'Correct verification_status' );
        cmp_ok( $domain->is_auto_renew,        '==', 1,                    'Correct is_auto_renew' );
        cmp_ok( $domain->is_locked,            '==', 1,                    'Correct is_locked' );
        cmp_ok( $domain->is_private,           '==', 1,                    'Correct is_private' );
        cmp_ok( $domain->created_date->ymd,    'eq', DateTime->now( time_zone => 'UTC' )->ymd, 'Correct created_date' );
        cmp_ok( $domain->expiration_date->ymd, 'eq', DateTime->now( time_zone => 'UTC' )->add( years => 1 )->ymd,
            'Correct expiration_date' );
        is_deeply( $request->ns, $domain->ns, 'Correct nameservers' );

        for my $contact_type (qw( registrant_contact admin_contact technical_contact billing_contact )) {
            is_deeply( $domain->$contact_type, $request->$contact_type, "Correct $contact_type" );
        }
    }
};

subtest 'Attempt to Register Unavailable' => sub {
    my $eNom = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Registration->new({
            name               => 'enom.com',
            ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
            is_ns_fail_fatal   => 0,
            is_locked          => 0,
            is_private         => 0,
            is_auto_renew      => 0,
            years              => 1,
            is_queueable       => 0,
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        });
    } 'Lives through creating request object';

    throws_ok {
        $eNom->register_domain( request => $request );
    } qr/Domain not available for registration/, 'Throws on registering unavailable domain';
};

done_testing;
