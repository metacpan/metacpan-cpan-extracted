#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

use WWW::LogicBoxes::PrivateNameServer;

my $logic_boxes = create_api();

subtest 'Modify Private Nameserver IP For Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->modify_private_nameserver_ip(
            domain_id => 999999999,
            name      => 'ns1.does-not-exist.com',
            old_ip    => '4.2.2.1',
            new_ip    => '8.8.8.8',
        );
    } qr/No such domain/, 'Throws on domain that does not exist';
};

subtest 'Modify Private Nameserver IP For Nameserver That Does Not Exist' => sub {
    my $domain = create_domain();

    throws_ok {
        $logic_boxes->modify_private_nameserver_ip(
            domain_id => $domain->id,
            name      => 'ns1.' . $domain->name,
            old_ip    => '4.2.2.1',
            new_ip    => '8.8.8.8',
        );
    } qr/No such existing private nameserver/, 'Throws on private nameserver that does not exist';
};

subtest 'Modify Private Nameserver IP - No Change To IP' => sub {
    my $domain = create_domain();
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1' ],
    );

    lives_ok {
        $logic_boxes->create_private_nameserver( $private_nameserver );
    } 'Lives through creation of private nameserver';

    throws_ok {
        $logic_boxes->modify_private_nameserver_ip(
            domain_id => $domain->id,
            name      => $private_nameserver->name,
            old_ip    => '4.2.2.1',
            new_ip    => '4.2.2.1',
        );
    } qr/Same value for old and new private nameserver ip/, 'Throws on no change to private nameserver';
};

subtest 'Modify Private Nameserver IP - Nameserver Does Not Have IP' => sub {
    my $domain = create_domain();
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1' ],
    );

    lives_ok {
        $logic_boxes->create_private_nameserver( $private_nameserver );
    } 'Lives through creation of private nameserver';

    throws_ok {
        $logic_boxes->modify_private_nameserver_ip(
            domain_id => $domain->id,
            name      => $private_nameserver->name,
            old_ip    => '8.8.8.8',
            new_ip    => '9.9.9.9',
        );
    } qr/Nameserver does not have specified ip/, 'Throws on no change to private namesver';
};

subtest 'Modify Private Nameserver IP - Change To IP Already In Use' => sub {
    my $domain = create_domain();
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1' ],
    );

    lives_ok {
        $logic_boxes->create_private_nameserver( $private_nameserver );
    } 'Lives through creation of private nameserver';

    my $existing_private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns2.' . $domain->name,
        ips       => [ '8.8.8.8' ],
    );

    lives_ok {
        $logic_boxes->create_private_nameserver( $existing_private_nameserver );
    } 'Lives through creation of private nameserver';

    lives_ok {
        $logic_boxes->modify_private_nameserver_ip(
            domain_id => $domain->id,
            name      => $private_nameserver->name,
            old_ip    => '4.2.2.1',
            new_ip    => '8.8.8.8',
        );
    } 'Allows multiple private nameservers to be assigned to same ip';


    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
    if( cmp_ok( scalar @{ $retrieved_domain->private_nameservers }, '==', 2, 'Correct number of private nameservers' ) ) {
        for my $retrieved_private_nameserver (@{ $retrieved_domain->private_nameservers }) {
            subtest $retrieved_private_nameserver->name => sub {
                cmp_bag( $retrieved_private_nameserver->ips, [ '8.8.8.8' ], 'Correct ips' );
            };
        }
    }
};

subtest 'Modify Private Nameserver IP' => sub {
    my %ips = (
        IPv4 => { original_ip => '8.8.4.4', updated_ip => '8.8.8.8' },
        IPv6 => { original_ip => '2001:4860:4860:0:0:0:0:8844', updated_ip => '2001:4860:4860:0:0:0:0:8888' },
    );

    for my $ip_version ( keys %ips ) {
        subtest $ip_version => sub {
            my $original_ip = $ips{ $ip_version }{ original_ip };
            my $updated_ip  = $ips{ $ip_version }{ updated_ip };

            my $domain = create_domain();
            my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
                domain_id => $domain->id,
                name      => 'ns1.' . $domain->name,
                ips       => [ $original_ip ],
            );

            lives_ok {
                $logic_boxes->create_private_nameserver( $private_nameserver );
            } 'Lives through creation of private nameserver';

            lives_ok {
                $logic_boxes->modify_private_nameserver_ip(
                    domain_id => $domain->id,
                    name      => $private_nameserver->name,
                    old_ip    => $original_ip,
                    new_ip    => $updated_ip,
                );
            } 'Lives through changing private nameserver ip';

            my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
            if( cmp_ok( scalar @{ $retrieved_domain->private_nameservers }, '==', 1, 'Correct number of private nameservers' ) ) {
                my $retrieved_private_nameserver = $retrieved_domain->private_nameservers->[0];

                cmp_ok( $retrieved_private_nameserver->name, 'eq', $private_nameserver->name, 'Correct name' );
                cmp_bag( $retrieved_private_nameserver->ips, [ $updated_ip ], 'Correct ips' );
            }
        };
    }
};

done_testing;
