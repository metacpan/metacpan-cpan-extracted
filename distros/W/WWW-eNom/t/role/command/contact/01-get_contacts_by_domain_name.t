#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Contact qw( create_contact mock_get_contacts );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::DomainRequest::Registration;

subtest 'Get Contacts For Unregistered Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetContacts',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->get_contacts_by_domain_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all();
};

subtest 'Get Contacts For Domain Registered To Someone Else' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetContacts',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->get_contacts_by_domain_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all();
};

subtest 'Get Contacts For Domain With All Contact Defined' => sub {
    my $api = create_api();

    my $contacts = {
        registrant_contact => create_contact({
            organization_name => 'London Univeristy',
            job_title         => 'Bug Squisher',
        }),
        admin_contact      => create_contact({
            fax_number        => '18005551212',
        }),
        technical_contact  => create_contact(),
        billing_contact    => create_contact(),
    };

    my $domain = create_domain({
        registrant_contact => $contacts->{registrant_contact},
        admin_contact      => $contacts->{admin_contact},
        technical_contact  => $contacts->{technical_contact},
        billing_contact    => $contacts->{billing_contact},
    });

    my $mocked_api = mock_get_contacts(
        registrant_contact => $domain->registrant_contact,
        admin_contact      => $domain->admin_contact,
        technical_contact  => $domain->technical_contact,
        billing_contact    => $domain->billing_contact,
    );

    my $retrieved_contacts;
    lives_ok {
        $retrieved_contacts = $api->get_contacts_by_domain_name( $domain->name );
    } 'Lives through retrieving contacts';

    $mocked_api->unmock_all();

    for my $contact_type (keys %{ $retrieved_contacts } ) {
        subtest "$contact_type" => sub {
            delete $retrieved_contacts->{is_pending_irtp};
            is_deeply( $retrieved_contacts->{ $contact_type }, $contacts->{ $contact_type }, "Correct $contact_type" );
        };
    }
};

subtest 'Get Contacts For Domain Missing Contact' => sub {
    my $api            = create_api();
    my $contact        = create_contact();
    my $domain_request = WWW::eNom::DomainRequest::Registration->new({
        name               => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.com',
        ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
        is_ns_fail_fatal   => 0,
        is_locked          => 0,
        is_private         => 0,
        is_auto_renew      => 0,
        years              => 1,
        is_queueable       => 0,
        registrant_contact => $contact,
        admin_contact      => $contact,
        technical_contact  => $contact,
        billing_contact    => $contact,
    });

    my $domain_creation_request = $domain_request->construct_request();
    for my $field ( keys %{ $domain_creation_request } ) {
        if( $field =~ m/(?:Admin)|(?:Tech)|(?:AuxBilling)/ ) {
            delete $domain_creation_request->{ $field };
        }
    }

    my $mocked_api = mock_response(
        method   => 'Purchase',
        response => { }
    );

    my $domain_response;
    lives_ok {
        $domain_response = $api->submit({
            method => 'Purchase',
            params => $domain_creation_request,
        });
    } 'Lives through domain registration';

    if( !$ENV{USE_MOCK} ) {
        note('Sleeping to allow eNom time to create the account');
        sleep 5;
    }

    mock_get_contacts(
        mocked_api         => $mocked_api,
        registrant_contact => $contact,
        admin_contact      => $contact,
        technical_contact  => $contact,
        billing_contact    => $contact,
    );

    my $retrieved_contacts;
    lives_ok {
        $retrieved_contacts = $api->get_contacts_by_domain_name( $domain_request->name );
    } 'Lives through retrieving contacts';

    $mocked_api->unmock_all();

    delete $retrieved_contacts->{is_pending_irtp};
    for my $contact_type (keys %{ $retrieved_contacts } ) {
        subtest "$contact_type" => sub {
            is_deeply( $retrieved_contacts->{ $contact_type }, $contact, "Correct $contact_type" );
        };
    }
};

subtest 'Get Contacts For Domain With No Manually Specific Contacts (Reseller Only)' => sub {
    my $api            = create_api();
    my $contact        = create_contact();
    my $domain_request = WWW::eNom::DomainRequest::Registration->new({
        name               => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.com',
        ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
        is_ns_fail_fatal   => 0,
        is_locked          => 0,
        is_private         => 0,
        is_auto_renew      => 0,
        years              => 1,
        is_queueable       => 0,
        registrant_contact => $contact,
        admin_contact      => $contact,
        technical_contact  => $contact,
        billing_contact    => $contact,
    });

    my $domain_creation_request = $domain_request->construct_request();
    for my $field ( keys %{ $domain_creation_request } ) {
        if( $field =~ m/(?:Registrant)|(?:Admin)|(?:Tech)|(?:AuxBilling)/ ) {
            delete $domain_creation_request->{ $field };
        }
    }

    my $mocked_api = mock_response(
        method   => 'Purchase',
        response => { }
    );

    my $domain_response;
    lives_ok {
        $domain_response = $api->submit({
            method => 'Purchase',
            params => $domain_creation_request,
        });
    } 'Lives through domain registration';

    if( !$ENV{USE_MOCK} ) {
        note('Sleeping to allow eNom time to create the account');
        sleep 5;
    }

    mock_get_contacts(
        mocked_api         => $mocked_api,
        registrant_contact => $contact,
        admin_contact      => $contact,
        technical_contact  => $contact,
        billing_contact    => $contact,
    );

    my $retrieved_contacts;
    lives_ok {
        $retrieved_contacts = $api->get_contacts_by_domain_name( $domain_request->name );
    } 'Lives through retrieving contacts';
};

done_testing;
