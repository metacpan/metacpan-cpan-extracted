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

subtest 'Register Available US Domain - No Nexus Data' => sub {
    throws_ok {
        WWW::eNom::DomainRequest::Registration->new({
            name               => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.us',
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
    } qr/\.us domain registration require a nexus_purpose and a nexus_category/, 'Throws without nexus data';
};

subtest 'Register Available US Domain - With Privacy' => sub {
    throws_ok {
        WWW::eNom::DomainRequest::Registration->new({
            name               => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.us',
            ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
            is_ns_fail_fatal   => 0,
            is_locked          => 0,
            is_private         => 1,
            is_auto_renew      => 0,
            years              => 1,
            is_queueable       => 0,
            nexus_purpose      => 'P1',
            nexus_category     => 'C11',
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        });
    } qr/Domain Privacy is not available for \.us domains/, 'Privacy Not Allowed on .us Domains';
};

subtest 'Register Available US Domain - With Nexus Data' => sub {
    my $eNom = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Registration->new({
            name               => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.us',
            ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
            is_ns_fail_fatal   => 0,
            is_locked          => 0,
            is_private         => 0,
            is_auto_renew      => 0,
            years              => 1,
            is_queueable       => 0,
            nexus_purpose      => 'P1',
            nexus_category     => 'C11',
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        });
    } 'Lives through construction of request';

    my $domain;
    lives_ok {
        $domain = $eNom->register_domain( request => $request );
    } 'Lives through registering domain';

    if( isa_ok( $domain, 'WWW::eNom::Domain' ) ) {
        like( $domain->id, qr/^\d+$/, 'id looks numeric' );
        cmp_ok( $domain->name,                 'eq', $request->name,            'Correct name' );
        cmp_ok( $domain->status,               'eq', 'Registered',              'Correct status' );
        cmp_ok( $domain->verification_status,  'eq', 'Verification Not Needed', 'Correct verification_status' );
        cmp_ok( $domain->is_auto_renew,        '==', 0,                         'Correct is_auto_renew' );
        cmp_ok( $domain->is_locked,            '==', 0,                         'Correct is_locked' );
        cmp_ok( $domain->is_private,           '==', 0,                         'Correct is_private' );
        cmp_ok( $domain->created_date->ymd,    'eq', DateTime->now( time_zone => 'UTC' )->ymd, 'Correct created_date' );
        cmp_ok( $domain->expiration_date->ymd, 'eq', DateTime->now( time_zone => 'UTC' )->add( years => 1 )->ymd,
            'Correct expiration_date' );
        is_deeply( $request->ns, $domain->ns, 'Correct nameservers' );

        for my $contact_type (qw( registrant_contact admin_contact technical_contact billing_contact )) {
            is_deeply( $domain->$contact_type, $request->$contact_type, "Correct $contact_type" );
        }
    }
};

done_testing;
