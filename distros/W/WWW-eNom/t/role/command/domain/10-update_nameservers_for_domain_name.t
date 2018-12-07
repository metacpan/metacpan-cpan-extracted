#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_domain_retrieval mock_update_nameserver $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::PrivateNameServer;

subtest 'Update Nameservers On Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method     => 'ModifyNS',
        response   => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    $mocked_api->mock( 'get_domain_name_servers_by_name', sub {
        note('Mocked WWW::eNom->get_domain_name_servers_by_name');

        return [ ];
    });

    throws_ok {
        $api->update_nameservers_for_domain_name({
            domain_name => $UNREGISTERED_DOMAIN->name,
            ns          => [ 'ns1.enom.org', 'ns2.enom.org' ],
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Update Nameservers On Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method => 'ModifyNS',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    $mocked_api->mock( 'get_domain_name_servers_by_name', sub {
        note('Mocked WWW::eNom->get_domain_name_servers_by_name');

        return [ ];
    });

    mock_response(
        mocked_api => $mocked_api,
        method     => 'ModifyNS',
        response   => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->update_nameservers_for_domain_name({
            domain_name => $NOT_MY_DOMAIN->name,
            ns          => [ 'ns1.enom.org', 'ns2.enom.org' ],
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Update Nameservers - No Change' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $mocked_api = mock_response(
        method   => 'ModifyNS',
        response => {
            ErrCount => 0,
        }
    );

    mock_domain_retrieval(
        mocked_api    => $mocked_api,
        name          => $domain->name,
        is_private    => $domain->is_private,
        is_locked     => $domain->is_locked,,
        is_auto_renew => $domain->is_auto_renew,
        nameservers   => $domain->ns,
        registrant_contact => $domain->registrant_contact,
        admin_contact      => $domain->admin_contact,
        technical_contact  => $domain->technical_contact,
        billing_contact    => $domain->billing_contact,
    );

    my $updated_domain;
    lives_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => $domain->ns,
        });
    } 'Lives through updating nameservers';

    $mocked_api->unmock_all;

    is_deeply( $updated_domain->ns, $domain->ns, 'Correct ns' );
};

subtest 'Update Nameservers - Full Change - Valid Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $new_ns = [ 'ns1.enom.org', 'ns2.enom.org' ];

    my $mocked_api = mock_response(
        method   => 'ModifyNS',
        response => {
            ErrCount => 0,
        }
    );

    mock_domain_retrieval(
        mocked_api    => $mocked_api,
        name          => $domain->name,
        is_private    => $domain->is_private,
        is_locked     => $domain->is_locked,,
        is_auto_renew => $domain->is_auto_renew,
        nameservers   => $new_ns,
        registrant_contact => $domain->registrant_contact,
        admin_contact      => $domain->admin_contact,
        technical_contact  => $domain->technical_contact,
        billing_contact    => $domain->billing_contact,
    );

    my $updated_domain;
    lives_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => $new_ns,
        });
    } 'Lives through updating nameservers';

    $mocked_api->unmock_all;

    is_deeply( $updated_domain->ns, $new_ns, 'Correct ns' );
};

subtest 'Update Nameservers - Full Change - Invalid Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $mocked_api = mock_response(
        method   => 'ModifyNS',
        response => {
            ErrCount => 1,
            errors   => [ 'could not be registered' ],
        }
    );

    $mocked_api->mock( 'get_domain_name_servers_by_name', sub {
        note('Mocked WWW::eNom->get_domain_name_servers_by_name');

        return $domain->ns;
    });

    my $updated_domain;
    throws_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => [ 'ns1.' . $UNREGISTERED_DOMAIN->name, 'ns2.' . $UNREGISTERED_DOMAIN->name ],
        });
    } qr/Invalid Nameserver provided/, 'Throws on invalid nameservers';

    $mocked_api->unmock_all;
};

subtest 'Update Nameservers - Remove a Private Nameserver' => sub {
    my $api    = create_api();

    my @initial_nameservers = ( 'ns1.enom.com', 'ns2.enom.com' );
    my $domain = create_domain( ns => \@initial_nameservers );

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name   => 'ns1.' . $domain->name,
        ip     => '4.2.2.1',
    );

    my $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ @initial_nameservers, $private_nameserver ],
    );

    lives_ok {
        $api->create_private_nameserver({
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver,
        });
    } 'Lives through registering private nameserver';

    subtest 'Inspect NS Before Modification' => sub {
        my $retrieved_domain = $api->get_domain_by_name( $domain->name );
        cmp_bag( $retrieved_domain->ns, [ @initial_nameservers, $private_nameserver->name ], 'Correct ns' );

        my $retrieved_private_nameserver = $api->retrieve_private_nameserver_by_name(
            $private_nameserver->name
        );

        is_deeply( $retrieved_private_nameserver, $private_nameserver, 'Correct private nameserver' );
    };

    $mocked_api->unmock_all;

    $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => \@initial_nameservers,
    );

    my $times_called = 0;
    $mocked_api->mock('get_domain_name_servers_by_name', sub {
        note('Mocked WWW::eNom->get_domain_name_servers_by_name');

        if( $times_called == 0 ) {
            $times_called++;
            return [ @initial_nameservers, $private_nameserver->name ];
        }
        else {
            return \@initial_nameservers;
        }
    });

    my $updated_domain;
    lives_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => \@initial_nameservers,
        });
    } 'Lives through updating nameservers';

    subtest 'Inspect NS After Modification' => sub {
        my $retrieved_domain = $api->get_domain_by_name( $domain->name );
        cmp_bag( $retrieved_domain->ns, \@initial_nameservers, 'Correct ns' );

        mock_response(
            mocked_api => $mocked_api,
            method     => 'CheckNSStatus',
            response   => {
                ErrCount => 1,
                errors   => [ 'Error 545 - Name server does not exist' ],
            }
        );

        throws_ok {
            $api->retrieve_private_nameserver_by_name(
                $private_nameserver->name
            );
        } qr/Nameserver does not exist/, 'Private nameserver was deleted';
    };

    $mocked_api->unmock_all;
};

done_testing;
