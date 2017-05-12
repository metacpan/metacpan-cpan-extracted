#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::PrivateNameServer;

subtest 'Update Nameservers On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->update_nameservers_for_domain_name({
            domain_name => $UNREGISTERED_DOMAIN->name,
            ns          => [ 'ns1.enom.org', 'ns2.enom.org' ],
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Update Nameservers On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->update_nameservers_for_domain_name({
            domain_name => $NOT_MY_DOMAIN->name,
            ns          => [ 'ns1.enom.org', 'ns2.enom.org' ],
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Update Nameservers - No Change' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $updated_domain;
    lives_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => $domain->ns,
        });
    } 'Lives through updating nameservers';

    is_deeply( $updated_domain->ns, $domain->ns, 'Correct ns' );
};

subtest 'Update Nameservers - Full Change - Valid Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $new_ns = [ 'ns1.enom.org', 'ns2.enom.org' ];

    my $updated_domain;
    lives_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => $new_ns,
        });
    } 'Lives through updating nameservers';

    is_deeply( $updated_domain->ns, $new_ns, 'Correct ns' );
};

subtest 'Update Nameservers - Full Change - Invalid Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $updated_domain;
    throws_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => [ 'ns1.' . $UNREGISTERED_DOMAIN->name, 'ns2.' . $UNREGISTERED_DOMAIN->name ],
        });
    } qr/Invalid Nameserver provided/, 'Throws on invalid nameservers';
};

subtest 'Update Namservers - Remove a Private Nameserver' => sub {
    my $api    = create_api();

    my @initial_nameservers = ( 'ns1.enom.com', 'ns2.enom.com' );
    my $domain = create_domain( ns => \@initial_nameservers );

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name   => 'ns1.' . $domain->name,
        ip     => '4.2.2.1',
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

        throws_ok {
            $api->retrieve_private_nameserver_by_name(
                $private_nameserver->name
            );
        } qr/Nameserver does not exist/, 'Private nameserver was deleted';
    };
};

done_testing;
