#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( IP );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::PrivateNameServer;

subtest 'Update Private Nameserver On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->update_private_nameserver_ip(
            name   => 'ns1.' . $UNREGISTERED_DOMAIN->name,
            old_ip => '4.2.2.1',
            new_ip => '8.8.8.8',
        );
    } qr/Nameserver does not exist/, 'Throws on unregistered domain';
};

subtest 'Update Private Nameserver On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->update_private_nameserver_ip(
            name   => 'ns1.' . $NOT_MY_DOMAIN->name,
            old_ip => '4.2.2.1',
            new_ip => '8.8.8.8',
        );
    } qr/Nameserver not found in your account/, 'Throws on not my domain';
};

subtest 'Update Private Nameserver That Does Not Exist' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    throws_ok {
        $api->update_private_nameserver_ip(
            name   => 'ns1.' . $domain->name,
            old_ip => '4.2.2.1',
            new_ip => '8.8.8.8',
        );
    } qr/Nameserver does not exist/, 'Throws on non existant nameserver';
};

subtest 'Update Private Nameserver' => sub {
    test_update_private_nameserver(
        old_ip => '4.2.2.1',
        new_ip => '8.8.8.8',
    );
};

subtest 'Update Private Nameserver - No Changes' => sub {
    test_update_private_nameserver(
        old_ip => '4.2.2.1',
        new_ip => '4.2.2.1',
    );
};

subtest 'Update Private Nameserver - Wrong old_ip' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
    );

    lives_ok {
        $api->create_private_nameserver(
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver,
        );
    } 'Lives through creation of private nameserver';

    throws_ok {
        $api->update_private_nameserver_ip(
            name   => $private_nameserver->name,
            old_ip => reverse $private_nameserver->ip,
            new_ip => '8.8.8.8',
        );
    } qr/Incorrect old_ip/, 'Throws on bad old_ip';
};

done_testing;

sub test_update_private_nameserver {
    my ( %args ) = validated_hash(
        \@_,
        old_ip => { isa => IP },
        new_ip => { isa => IP },
    );

    my $api    = create_api();
    my $domain = create_domain();

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => $args{old_ip},
    );

    lives_ok {
        $api->create_private_nameserver(
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver,
        );
    } 'Lives through creation of private nameserver';

    lives_ok {
        $api->update_private_nameserver_ip(
            name   => $private_nameserver->name,
            old_ip => $private_nameserver->ip,
            new_ip => $args{new_ip},
        );
    } 'Lives through updating private nameserver';

    my $retrieved_private_nameserver = $api->retrieve_private_nameserver_by_name( $private_nameserver->name );

    cmp_ok( $retrieved_private_nameserver->ip, 'eq', $args{new_ip}, 'Correct ip' );

    return $private_nameserver;
}
